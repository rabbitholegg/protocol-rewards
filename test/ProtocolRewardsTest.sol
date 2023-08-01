// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../src/ProtocolRewards.sol";

import "./utils/MockNFTs.sol";

contract ProtocolRewardsTest is Test {
    ProtocolRewards internal protocolRewards;

    address internal collector;
    address internal creator;
    address internal mintReferral;
    address internal createReferral;
    address internal zora;

    function setUp() public virtual {
        protocolRewards = new ProtocolRewards();

        vm.label(address(protocolRewards), "PROTOCOL_REWARDS");

        collector = makeAddr("collector");
        creator = makeAddr("creator");
        mintReferral = makeAddr("mintReferral");
        createReferral = makeAddr("createReferral");
        zora = makeAddr("zora");
    }
}