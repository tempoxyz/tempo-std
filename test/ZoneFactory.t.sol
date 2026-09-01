// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.13 <0.9.0;

import {StdPrecompiles} from "../src/StdPrecompiles.sol";
import {Tempo} from "../src/Tempo.sol";
import {IZoneFactory} from "../src/interfaces/IZoneFactory.sol";
import {IZonePortal} from "../src/interfaces/IZonePortal.sol";

contract ZoneFactoryExportsTest is Tempo {
    address internal constant EXPECTED_ZONE_FACTORY_ADDRESS = 0x5AF2000000000000000000000000000000000000;
    address internal constant EXPECTED_ZONE_PORTAL_IMPL_ADDRESS = 0x5AD1000000000000000000000000000000000000;
    address internal constant EXPECTED_ZONE_VERIFIER_ADDRESS = 0x5A56000000000000000000000000000000000000;
    address internal constant EXPECTED_ZONE_MESSENGER_ADDRESS = 0x5A4D000000000000000000000000000000000000;

    function testAddressExports() public pure {
        require(StdPrecompiles.ZONE_FACTORY_ADDRESS == EXPECTED_ZONE_FACTORY_ADDRESS, "StdPrecompiles zone factory address");
        require(StdPrecompiles.ZONE_PORTAL_IMPL_ADDRESS == EXPECTED_ZONE_PORTAL_IMPL_ADDRESS, "StdPrecompiles portal impl address");
        require(StdPrecompiles.ZONE_VERIFIER_ADDRESS == EXPECTED_ZONE_VERIFIER_ADDRESS, "StdPrecompiles verifier address");
        require(StdPrecompiles.ZONE_MESSENGER_ADDRESS == EXPECTED_ZONE_MESSENGER_ADDRESS, "StdPrecompiles messenger address");
        require(ZONE_FACTORY == EXPECTED_ZONE_FACTORY_ADDRESS, "Tempo zone factory address");
    }

    function testTypedExports() public pure {
        require(address(StdPrecompiles.ZONE_FACTORY) == EXPECTED_ZONE_FACTORY_ADDRESS, "StdPrecompiles typed export");
        require(address(zoneFactory) == EXPECTED_ZONE_FACTORY_ADDRESS, "Tempo typed export");
    }

    function testAbiSelectors() public pure {
        require(IZoneFactory.owner.selector == bytes4(keccak256("owner()")), "owner selector");
        require(IZoneFactory.transferOwnership.selector == bytes4(keccak256("transferOwnership(address)")), "transferOwnership selector");
        require(IZoneFactory.nextZoneId.selector == bytes4(keccak256("nextZoneId()")), "nextZoneId selector");
        require(IZoneFactory.zones.selector == bytes4(keccak256("zones(uint32)")), "zones selector");
        require(IZoneFactory.isZonePortal.selector == bytes4(keccak256("isZonePortal(address)")), "isZonePortal selector");

        require(IZoneFactory.InvalidToken.selector == bytes4(keccak256("InvalidToken()")), "InvalidToken selector");
        require(IZoneFactory.TokenTransferPolicyNotSet.selector == bytes4(keccak256("TokenTransferPolicyNotSet()")), "TokenTransferPolicyNotSet selector");
        require(IZoneFactory.InvalidClosedLoopConfig.selector == bytes4(keccak256("InvalidClosedLoopConfig()")), "InvalidClosedLoopConfig selector");
        require(IZoneFactory.NotOwner.selector == bytes4(keccak256("NotOwner()")), "NotOwner selector");
        require(IZoneFactory.InvalidAdmin.selector == bytes4(keccak256("InvalidAdmin()")), "InvalidAdmin selector");
        require(IZoneFactory.InvalidSequencerSet.selector == bytes4(keccak256("InvalidSequencerSet()")), "InvalidSequencerSet selector");
        require(IZoneFactory.AlreadyInitialized.selector == bytes4(keccak256("AlreadyInitialized()")), "AlreadyInitialized selector");
        require(IZoneFactory.TokenMetadataTooLong.selector == bytes4(keccak256("TokenMetadataTooLong()")), "TokenMetadataTooLong selector");
    }
}
