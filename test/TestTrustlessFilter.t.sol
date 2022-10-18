// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/mocks/ERC721TrustlessFilterMock.sol";

contract TestTrustlessFilter is Test {
    ERC721TrustlessFilterMock public erc721;

    address user1 = vm.addr(1);
    uint256 tokenId1 = 1;
    address marketplace1 = vm.addr(100);

    function setUp() public {
        erc721 = new ERC721TrustlessFilterMock("Token", "TKN");
    }

    function testVoteInvalid() public {
        vm.expectRevert("ERC721: invalid token ID");
        erc721.vote(marketplace1, tokenId1, true);

        erc721.mint(user1, tokenId1);

        vm.expectRevert("Not owner or operator of token");
        erc721.vote(marketplace1, tokenId1, true);
    }

    function testVoteStates() public {
        erc721.mint(user1, tokenId1);
        vm.startPrank(user1);

        vm.expectRevert("No vote cast");
        erc721.getVote(marketplace1, tokenId1);
        assertEq(erc721.getAllowTotal(marketplace1), 0);
        assertEq(erc721.getBlockTotal(marketplace1), 0);

        erc721.vote(marketplace1, tokenId1, true);
        assertEq(erc721.getVote(marketplace1, tokenId1), true);
        assertEq(erc721.getAllowTotal(marketplace1), 1);
        assertEq(erc721.getBlockTotal(marketplace1), 0);

        erc721.vote(marketplace1, tokenId1, false);
        assertEq(erc721.getVote(marketplace1, tokenId1), false);
        assertEq(erc721.getAllowTotal(marketplace1), 0);
        assertEq(erc721.getBlockTotal(marketplace1), 1);

        erc721.vote(marketplace1, tokenId1, true);
        assertEq(erc721.getVote(marketplace1, tokenId1), true);
        assertEq(erc721.getAllowTotal(marketplace1), 1);
        assertEq(erc721.getBlockTotal(marketplace1), 0);
    }

    function testMayTransfer() public {
        erc721.setMinBlockVotesNeeded(100);

        // 10 votes against
        for (uint256 i = 1; i <= 10; ++i) {
            address user = vm.addr(i);
            erc721.mint(user, i);
            vm.prank(user);
            erc721.vote(marketplace1, i, false);
        }

        // Will still be true because threshold hasn't been met
        assertEq(erc721.mayTransfer(marketplace1), true);

        // Now returns false because threshold is updated
        erc721.setMinBlockVotesNeeded(10);
        assertEq(erc721.mayTransfer(marketplace1), false);

        // Always true when there the threshold is 0
        erc721.setMinBlockVotesNeeded(0);
        assertEq(erc721.mayTransfer(marketplace1), true);

        // Revert threshold change
        erc721.setMinBlockVotesNeeded(10);

        // Change 5 votes to allow
        for (uint256 i = 1; i <= 5; ++i) {
            address user = vm.addr(i);
            vm.prank(user);
            erc721.vote(marketplace1, i, true);
        }

        // Should be true because tie breaker goes to allow
        assertEq(erc721.mayTransfer(marketplace1), true);
    }
}
