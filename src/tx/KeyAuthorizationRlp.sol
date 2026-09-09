// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

/// @notice Structural validation for one canonical RLP SignedKeyAuthorization.
/// @dev Checks the wire schema, not signature recovery or chain-state authorization rules.
library KeyAuthorizationRlp {
    error InvalidKeyAuthorization();

    struct Item {
        uint256 start;
        uint256 end;
        bool list;
    }

    function validate(bytes memory data) internal pure {
        Item memory outer = _read(data, 0, data.length);
        _check(outer.list && outer.end == data.length);
        Item memory authorization = _read(data, outer.start, outer.end);
        _authorization(data, authorization);
        Item memory signature = _read(data, authorization.end, outer.end);
        _check(!signature.list && signature.end == outer.end);
        uint256 length = signature.end - signature.start;
        if (length == 65) {
            uint8 v = uint8(data[signature.end - 1]);
            _check(v <= 1 || v == 27 || v == 28);
        } else {
            _check(length > 0);
            uint8 kind = uint8(data[signature.start]);
            // Primitive P256 (type + 129 bytes) or WebAuthn (type + up to 2048 bytes).
            _check((kind == 1 && length == 130) || (kind == 2 && length >= 129 && length <= 2049));
        }
    }

    function _authorization(bytes memory data, Item memory parent) private pure {
        _check(parent.list);
        uint256 offset = parent.start;
        uint256 count = 0;
        bool present = false;
        while (offset < parent.end) {
            Item memory item = _read(data, offset, parent.end);
            present = item.list || item.end > item.start;
            if (count == 0 || count == 3) {
                _uint(data, item, 8);
            } else if (count == 1) {
                _uint(data, item, 1);
                _check(!present || uint8(data[item.start]) <= 2);
            } else if (count == 2) {
                _bytes(item, 20);
            } else if (count == 4 || count == 5) {
                if (present) _array(data, item, count == 4 ? 0 : 1);
            } else if (count == 6) {
                if (present) _bytes(item, 32);
            } else if (count == 7) {
                _uint(data, item, 1);
                _check(!present || data[item.start] == 0x01);
            } else if (count == 8) {
                if (present) _bytes(item, 20);
            } else {
                revert InvalidKeyAuthorization();
            }
            offset = item.end;
            count++;
        }
        // Optional trailing None values must be omitted, not encoded as empty strings.
        _check(count >= 3 && (count == 3 || present));
    }

    // kind: 0 = token limits, 1 = call scopes, 2 = selector rules, 3 = recipients.
    // Recursion is bounded by the schema (scopes -> rules -> recipients).
    function _array(bytes memory data, Item memory parent, uint256 kind) private pure {
        _check(parent.list);
        uint256 offset = parent.start;
        while (offset < parent.end) {
            Item memory item = _read(data, offset, parent.end);
            if (kind == 3) {
                _bytes(item, 20);
            } else {
                _check(item.list);
                Item memory first = _read(data, item.start, item.end);
                _bytes(first, kind == 2 ? 4 : 20);
                Item memory second = _read(data, first.end, item.end);
                if (kind == 0) {
                    _uint(data, second, 32);
                    if (second.end < item.end) {
                        Item memory period = _read(data, second.end, item.end);
                        _uint(data, period, 8);
                        _check(period.end > period.start && period.end == item.end);
                    }
                } else {
                    _array(data, second, kind + 1);
                    _check(second.end == item.end);
                }
            }
            offset = item.end;
        }
    }

    function _bytes(Item memory item, uint256 length) private pure {
        _check(!item.list && item.end - item.start == length);
    }

    function _uint(bytes memory data, Item memory item, uint256 maxLength) private pure {
        _check(!item.list && item.end - item.start <= maxLength);
        _check(item.start == item.end || data[item.start] != 0);
    }

    /// @dev Reads a canonical RLP header within its parent's bounds, without copying payloads.
    function _read(bytes memory data, uint256 offset, uint256 end) private pure returns (Item memory item) {
        _check(offset < end);
        uint8 prefix = uint8(data[offset]);
        if (prefix < 0x80) return Item(offset, offset + 1, false);
        item.list = prefix >= 0xc0;
        uint256 shortBase = item.list ? 0xc0 : 0x80;
        uint256 longBase = shortBase + 55;
        uint256 length = 0;
        item.start = offset + 1;
        if (prefix <= longBase) {
            length = prefix - shortBase;
        } else {
            uint256 lengthBytes = prefix - longBase;
            _check(lengthBytes <= end - item.start);
            _check(data[item.start] != 0);
            for (uint256 i = 0; i < lengthBytes; i++) {
                length = (length << 8) | uint8(data[item.start++]);
            }
            _check(length > 55);
        }
        _check(length <= end - item.start);
        item.end = item.start + length;
        if (!item.list && length == 1) _check(uint8(data[item.start]) >= 0x80);
    }

    function _check(bool valid) private pure {
        if (!valid) revert InvalidKeyAuthorization();
    }
}
