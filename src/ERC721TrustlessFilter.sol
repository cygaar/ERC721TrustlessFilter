// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721TrustlessFilter is ERC721, Ownable {
    using BitMaps for BitMaps.BitMap;

    struct VoteInfo {
        BitMaps.BitMap allowVotes;
        BitMaps.BitMap blockVotes;
        uint256 allowTotal;
        uint256 blockTotal;
    }

    mapping(address => VoteInfo) internal _voteInfo;

    uint256 public minBlockVotesNeeded;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256)
        internal
        virtual
        override (ERC721)
    {
        if (from != address(0) && to != address(0) && !mayTransfer(msg.sender)) {
            revert("ERC721TrustlessFilter: illegal operator");
        }
        super._beforeTokenTransfer(from, to, tokenId, 1);
    }

    function mayTransfer(address operator) public view returns (bool) {
        if (minBlockVotesNeeded == 0) return true;

        VoteInfo storage operatorVote = _voteInfo[operator];
        uint256 allowTotal = operatorVote.allowTotal;
        uint256 blockTotal = operatorVote.blockTotal;

        return blockTotal < minBlockVotesNeeded || blockTotal <= allowTotal;
    }

    function vote(address operator, uint256 tokenId, bool newVote) external {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert("Not owner or operator of token");
        }

        VoteInfo storage operatorVote = _voteInfo[operator];
        bool previouslyAllow = operatorVote.allowVotes.get(tokenId);
        bool previouslyBlock = operatorVote.blockVotes.get(tokenId);

        if (previouslyAllow && newVote || previouslyBlock && !newVote) {
            return;
        }

        // Handle cases when the vote has changed
        if (previouslyAllow && !newVote) {
            --operatorVote.allowTotal;
            operatorVote.allowVotes.unset(tokenId);
        } else if (previouslyBlock && newVote) {
            --operatorVote.blockTotal;
            operatorVote.blockVotes.unset(tokenId);
        }

        // Update talllies with new vote
        if (newVote) {
            ++operatorVote.allowTotal;
            operatorVote.allowVotes.set(tokenId);
        } else {
            ++operatorVote.blockTotal;
            operatorVote.blockVotes.set(tokenId);
        }
    }

    function setMinBlockVotesNeeded(uint256 value) external onlyOwner {
        minBlockVotesNeeded = value;
    }
}
