// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {StdPrecompiles} from "../src/StdPrecompiles.sol";
import {Tempo} from "../src/Tempo.sol";
import {ICurrentCommittee} from "../src/interfaces/ICurrentCommittee.sol";

contract CurrentCommitteeExportsTest is Tempo {
    address internal constant EXPECTED_ADDRESS = 0xC077e00000000000000000000000000000000000;

    function testAddressExports() public pure {
        require(StdPrecompiles.CURRENT_COMMITTEE_ADDRESS == EXPECTED_ADDRESS, "StdPrecompiles address");
        require(CURRENT_COMMITTEE == EXPECTED_ADDRESS, "Tempo address");
    }

    function testTypedExports() public pure {
        require(address(StdPrecompiles.CURRENT_COMMITTEE) == EXPECTED_ADDRESS, "StdPrecompiles typed export");
        require(address(currentCommittee) == EXPECTED_ADDRESS, "Tempo typed export");
    }

    function testAbiSelectors() public pure {
        require(
            ICurrentCommittee.getCommitteeMembers.selector == bytes4(keccak256("getCommitteeMembers()")),
            "getCommitteeMembers selector"
        );
        require(
            ICurrentCommittee.setCommitteeMembers.selector
                == bytes4(keccak256("setCommitteeMembers(uint64,bytes32[])")),
            "setCommitteeMembers selector"
        );
        require(ICurrentCommittee.Unauthorized.selector == bytes4(keccak256("Unauthorized()")), "Unauthorized selector");
    }
}
