// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ProtocolRewardsTest.sol";
import {RewardsSettings} from "../../src/abstract/RewardSplits.sol";

contract ERC721RewardsTest is ProtocolRewardsTest {
    MockERC721 internal mockERC721;

    function setUp() public override {
        super.setUp();

        mockERC721 = new MockERC721(creator, createReferral, address(protocolRewards), zora);

        vm.label(address(mockERC721), "MOCK_ERC721");
    }

    function testValidateFreeMintTotalComputation(uint16 numTokens) public {
        uint256 expectedTotal = mockERC721.computeTotalReward(numTokens);

        RewardsSettings memory settings = mockERC721.computeFreeMintRewards(numTokens);

        uint256 actualTotal = settings.creatorReward +
            settings.createReferralReward +
            settings.mintReferralReward +
            settings.firstMinterReward +
            settings.zoraReward;

        assertEq(expectedTotal, actualTotal);
    }

    function testValidatePaidMintTotalComputation(uint32 numTokens) public {
        uint256 expectedTotal = mockERC721.computeTotalReward(numTokens);

        RewardsSettings memory settings = mockERC721.computePaidMintRewards(numTokens);

        uint256 actualTotal = settings.mintReferralReward + settings.createReferralReward + settings.firstMinterReward + settings.zoraReward;

        assertEq(expectedTotal, actualTotal);
    }

    function test721FreeMintDeposit(uint16 numTokens) public {
        vm.assume(numTokens > 0 && numTokens < 10_000);

        uint256 totalReward = mockERC721.computeTotalReward(numTokens);

        vm.deal(collector, totalReward);

        vm.prank(collector);
        mockERC721.mintWithRewards{value: totalReward}(collector, numTokens, mintReferral);

        RewardsSettings memory settings = mockERC721.computeFreeMintRewards(numTokens);

        assertEq(protocolRewards.totalSupply(), totalReward);
        assertEq(protocolRewards.balanceOf(creator), settings.creatorReward + settings.firstMinterReward);
        assertEq(protocolRewards.balanceOf(createReferral), settings.createReferralReward);
        assertEq(protocolRewards.balanceOf(mintReferral), settings.mintReferralReward);
        assertEq(protocolRewards.balanceOf(zora), settings.zoraReward);
    }

    function test721PaidMintDeposit(uint16 numTokens, uint256 pricePerToken) public {
        vm.assume(numTokens > 0 && numTokens < 10_000);
        vm.assume(pricePerToken > 0 && pricePerToken < 100 ether);

        mockERC721.setSalePrice(pricePerToken);

        uint256 totalReward = mockERC721.computeTotalReward(numTokens);
        uint256 totalSale = numTokens * pricePerToken;
        uint256 totalValue = totalReward + totalSale;

        vm.deal(collector, totalValue);

        vm.prank(collector);
        mockERC721.mintWithRewards{value: totalValue}(collector, numTokens, mintReferral);

        RewardsSettings memory settings = mockERC721.computePaidMintRewards(numTokens);

        assertEq(protocolRewards.totalSupply(), totalReward);
        assertEq(protocolRewards.balanceOf(creator), settings.firstMinterReward);
        assertEq(protocolRewards.balanceOf(createReferral), settings.createReferralReward);
        assertEq(protocolRewards.balanceOf(mintReferral), settings.mintReferralReward);
        assertEq(protocolRewards.balanceOf(zora), settings.zoraReward);
    }

    function test721FreeMintNullReferralRecipients(uint16 numTokens) public {
        vm.assume(numTokens > 0 && numTokens < 10_000);

        mockERC721 = new MockERC721(creator, address(0), address(protocolRewards), zora);

        uint256 totalReward = mockERC721.computeTotalReward(numTokens);

        vm.deal(collector, totalReward);

        vm.prank(collector);
        mockERC721.mintWithRewards{value: totalReward}(collector, numTokens, address(0));

        RewardsSettings memory settings = mockERC721.computeFreeMintRewards(numTokens);

        assertEq(protocolRewards.totalSupply(), totalReward);
        assertEq(protocolRewards.balanceOf(creator), settings.creatorReward + settings.firstMinterReward);
        assertEq(protocolRewards.balanceOf(zora), settings.zoraReward + settings.mintReferralReward + settings.createReferralReward);
    }

    function test721PaidMintNullReferralRecipient(uint16 numTokens, uint256 pricePerToken) public {
        vm.assume(numTokens > 0 && numTokens < 10_000);
        vm.assume(pricePerToken > 0 && pricePerToken < 100 ether);

        mockERC721 = new MockERC721(creator, address(0), address(protocolRewards), zora);

        mockERC721.setSalePrice(pricePerToken);

        uint256 totalReward = mockERC721.computeTotalReward(numTokens);
        uint256 totalSale = numTokens * pricePerToken;
        uint256 totalValue = totalReward + totalSale;

        vm.deal(collector, totalValue);

        vm.prank(collector);
        mockERC721.mintWithRewards{value: totalValue}(collector, numTokens, address(0));

        RewardsSettings memory settings = mockERC721.computePaidMintRewards(numTokens);

        assertEq(protocolRewards.totalSupply(), totalReward);
        assertEq(protocolRewards.balanceOf(creator), settings.firstMinterReward);
        assertEq(protocolRewards.balanceOf(zora), settings.zoraReward + settings.mintReferralReward + settings.createReferralReward);
    }

    function testSet721CreatorFundsRecipientAsContractIfNotSet(uint16 numTokens) public {
        vm.assume(numTokens > 0);

        mockERC721 = new MockERC721(address(0), createReferral, address(protocolRewards), zora);

        uint256 totalValue = mockERC721.computeTotalReward(numTokens);

        RewardsSettings memory settings = mockERC721.computeFreeMintRewards(numTokens);

        mockERC721.mintWithRewards{value: totalValue}(collector, numTokens, mintReferral);

        assertEq(protocolRewards.balanceOf(address(mockERC721)), settings.creatorReward + settings.firstMinterReward);
    }

    function testRevert721FreeMintInvalidEth(uint16 numTokens) public {
        vm.assume(numTokens > 0);

        vm.expectRevert(abi.encodeWithSignature("INVALID_ETH_AMOUNT()"));
        mockERC721.mintWithRewards(collector, numTokens, mintReferral);
    }

    function testRevert721PaidMintInvalidEth(uint16 numTokens, uint256 pricePerToken) public {
        vm.assume(numTokens > 0);
        vm.assume(pricePerToken > 0 && pricePerToken < 100 ether);

        mockERC721.setSalePrice(pricePerToken);

        vm.expectRevert(abi.encodeWithSignature("INVALID_ETH_AMOUNT()"));
        mockERC721.mintWithRewards(collector, numTokens, mintReferral);
    }
}
