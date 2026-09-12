#!/usr/bin/env python3
"""check-drift — compare tempo-std Solidity interface ABIs against the canonical
Rust precompile interfaces in the tempo node repository.

The node repository (tempoxyz/tempo) defines the canonical ABI for every native
precompile via `crate::sol!` blocks in crates/contracts/src/precompiles/*.rs.
tempo-std mirrors those interfaces in src/interfaces/*.sol. When the node ABI
changes (e.g. the T12 channel-reserve redesign), the Solidity mirror can fall
behind and calls silently break at runtime (valid selector, unknown to the node
— or worse, stale error selectors that no longer exist).

This script extracts function/error/event signatures from both sides, resolves
Solidity interface inheritance (`interface A is B { ... }`) transitively,
reduces everything to ABI-level types (parameter names, memory/calldata and
contract-typed aliases do not affect selectors), and diffs the sets.

Usage:
    scripts/check-drift.sh            (wrapper; see below for env vars)
    python3 scripts/check-drift.py --node /path/to/tempo

Environment (used by the shell wrapper):
    TEMPO_STD_DIR   default: repo root (parent of scripts/)
    TEMPO_NODE_DIR  default: ../tempo — a checkout of tempoxyz/tempo

Exit codes: 0 = no drift, 1 = drift detected, 2 = setup missing.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

# Solidity interface -> canonical Rust precompile file + Rust interface name.
# Vendored external contracts (ICreateX, IPermit2, IMulticall3) have no canonical
# counterpart and are intentionally not listed.
MAP = {
    "IAddressRegistry.sol": ("address_registry.rs", ["IAddressRegistry"]),
    "IAccountKeychain.sol": ("account_keychain.rs", ["IAccountKeychain"]),
    "ICurrentCommittee.sol": ("current_committee.rs", ["ICurrentCommittee"]),
    # The Solidity mirror models FeeManager as `IFeeManager is IFeeAMM`; the
    # canonical Rust side splits them into sibling interfaces in one file, so
    # the comparison unions both.
    "IFeeAMM.sol": ("tip_fee_manager.rs", ["ITIPFeeAMM"]),
    "IFeeManager.sol": ("tip_fee_manager.rs", ["IFeeManager", "ITIPFeeAMM"]),
    "INonce.sol": ("nonce.rs", ["INonce"]),
    "IReceivePolicyGuard.sol": ("receive_policy_guard.rs", ["IReceivePolicyGuard"]),
    "ISignatureVerifier.sol": ("signature_verifier.rs", ["ISignatureVerifier"]),
    "IStablecoinDEX.sol": ("stablecoin_dex.rs", ["IStablecoinDEX"]),
    "IStorageCredits.sol": ("storage_credits.rs", ["IStorageCredits"]),
    "ITIP20.sol": ("tip20.rs", ["ITIP20"]),
    "ITIP20Factory.sol": ("tip20_factory.rs", ["ITIP20Factory"]),
    "ITIP20RolesAuth.sol": ("tip20.rs", ["IRolesAuth"]),
    "ITIP403Registry.sol": ("tip403_registry.rs", ["ITIP403Registry"]),
    "ITempoStreamChannel.sol": ("tip20_channel_reserve.rs", ["ITIP20ChannelReserve"]),
    "IValidatorConfig.sol": ("validator_config.rs", ["IValidatorConfig"]),
    "IValidatorConfigV2.sol": ("validator_config_v2.rs", ["IValidatorConfigV2"]),
    "IZoneFactory.sol": ("zone_factory.rs", ["IZoneFactory"]),
}

IDENT = r"[A-Za-z_$][A-Za-z0-9_$]*"


def strip_comments(src: str) -> str:
    """Remove //, ///, and /* */ comments without touching banner art.

    Note: `///` and `//` are only stripped at line starts (after optional
    whitespace) so slash-runs inside `/*////...*/` banner art are untouched.
    Banner-art lines (only `/` and `*` characters) are removed first: their
    `*/`-looking substrings would otherwise terminate block comments early
    and leave the real closing `*/` opening a phantom comment that swallows
    code.
    """
    src = re.sub(r"^[ \t]*[/*]{10,}[ \t]*\n", "", src, flags=re.M)
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    src = re.sub(r"^[ \t]*///[^\n]*", "", src, flags=re.M)
    src = re.sub(r"^[ \t]*//[^/\n][^\n]*", "", src, flags=re.M)
    return src


def find_block(src: str, kind: str, name: str) -> str | None:
    """Return the body of `kind name { ... }` (brace-matched), or None."""
    m = re.search(rf"\b{kind}\s+{re.escape(name)}\b[^{{]*\{{", src)
    if not m:
        return None
    depth, i = 1, m.end()
    while i < len(src) and depth > 0:
        if src[i] == "{":
            depth += 1
        elif src[i] == "}":
            depth -= 1
        i += 1
    return src[m.end():i - 1]


def types_of(params: str) -> list[str]:
    """Reduce a parameter list to ABI-level type tokens."""
    params = params.strip()
    if not params:
        return []
    parts, depth, cur = [], 0, ""
    for ch in params:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += ch
    parts.append(cur)
    out = []
    for p in parts:
        p = re.sub(r"\b(memory|calldata|storage|indexed)\b", "", p).strip()
        toks = p.split()
        # drop a trailing parameter name (identifier) if a type precedes it
        if len(toks) > 1 and re.fullmatch(IDENT, toks[-1]):
            toks = toks[:-1]
        p = "".join(toks)
        # contract-typed params are plain addresses at the ABI level
        p = re.sub(rf"\bI{IDENT}\b", "address", p)
        out.append(p)
    return out


def extract_sigs(body: str) -> set[str]:
    sigs: set[str] = set()
    for m in re.finditer(rf"\bfunction\s+({IDENT})\s*\(([^)]*)\)", body):
        sigs.add("fn:" + m.group(1) + "(" + ",".join(types_of(m.group(2))) + ")")
    for m in re.finditer(rf"\berror\s+({IDENT})\s*\(([^)]*)\)", body):
        sigs.add("err:" + m.group(1) + "(" + ",".join(types_of(m.group(2))) + ")")
    for m in re.finditer(rf"\bevent\s+({IDENT})\s*\(([^)]*)\)", body):
        sigs.add("ev:" + m.group(1) + "(" + ",".join(types_of(m.group(2))) + ")")
    return sigs


class SolIndex:
    """Index of Solidity interfaces across src/interfaces for inheritance lookup."""

    def __init__(self, iface_dir: Path):
        self.blocks: dict[str, str] = {}
        self.bases: dict[str, list[str]] = {}
        for f in iface_dir.glob("*.sol"):
            src = strip_comments(f.read_text())
            for m in re.finditer(rf"\binterface\s+({IDENT})\s*(?:is\s+([\w\s,]+?))?\s*\{{", src):
                name = m.group(1)
                body = find_block(src, "interface", name)
                if body is None:
                    continue
                self.blocks[name] = body
                self.bases[name] = [b.strip() for b in (m.group(2) or "").split(",") if b.strip()]

    def sigs(self, name: str) -> set[str]:
        body = self.blocks.get(name)
        if body is None:
            return set()
        sigs = extract_sigs(body)
        for base in self.bases.get(name, []):
            sigs |= self.sigs(base)
        return sigs


def rust_sigs(rust_path: Path, ifaces: list[str]) -> set[str] | None:
    """Union of signatures across the listed canonical interfaces.

    Returns None when any listed interface is absent from the file.
    """
    src = strip_comments(rust_path.read_text())
    sigs: set[str] = set()
    for iface in ifaces:
        body = find_block(src, "interface", iface)
        if body is None:
            return None
        sigs |= extract_sigs(body)
    return sigs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--std", default=os.environ.get("TEMPO_STD_DIR"))
    ap.add_argument("--node", default=os.environ.get("TEMPO_NODE_DIR"))
    args = ap.parse_args()

    std_root = Path(args.std) if args.std else Path(__file__).resolve().parent.parent
    node_root = Path(args.node) if args.node else std_root.parent / "tempo"
    precompiles = node_root / "crates" / "contracts" / "src" / "precompiles"
    iface_dir = std_root / "src" / "interfaces"

    if not precompiles.is_dir():
        print(f"check-drift: canonical precompiles not found at {precompiles}", file=sys.stderr)
        print("check-drift: clone tempoxyz/tempo and point TEMPO_NODE_DIR at it", file=sys.stderr)
        return 2
    if not iface_dir.is_dir():
        print(f"check-drift: interfaces not found at {iface_dir}", file=sys.stderr)
        return 2

    index = SolIndex(iface_dir)
    drift = False

    for sol_file, (rust_file, rust_ifaces) in sorted(MAP.items()):
        sol_path = iface_dir / sol_file
        rust_path = precompiles / rust_file

        if not sol_path.is_file():
            print(f"MISSING Solidity interface: {sol_file} (canonical: {rust_file})")
            drift = True
            continue
        if not rust_path.is_file():
            print(f"MISSING canonical rust file: {rust_file} (for {sol_file})")
            drift = True
            continue

        # The Solidity mirror interface name: same file stem, minus the RolesAuth
        # special case whose canonical Rust name differs.
        sol_iface = sol_file.removesuffix(".sol")
        sol_sig_set = index.sigs(sol_iface)
        if not sol_sig_set:
            # fall back to any interface in the file (single-interface files)
            for name in index.blocks:
                if index.bases.get(name) is not None and name.startswith(sol_iface[:8]):
                    sol_sig_set = index.sigs(name)
                    break

        rs = rust_sigs(rust_path, rust_ifaces)
        if rs is None:
            print(f"MISSING canonical interface {'/'.join(rust_ifaces)} in {rust_file} (for {sol_file})")
            drift = True
            continue

        only_rust = rs - sol_sig_set
        only_sol = sol_sig_set - rs
        if only_rust or only_sol:
            print(f"DRIFT: {sol_file} vs {rust_file} ({'+'.join(rust_ifaces)})")
            for s in sorted(only_rust):
                print(f"  + canonical only: {s}")
            for s in sorted(only_sol):
                print(f"  - std only:      {s}")
            drift = True

    if not drift:
        print("check-drift: OK — all mirrored interfaces match the canonical Rust ABI.")
    return 1 if drift else 0


if __name__ == "__main__":
    sys.exit(main())
