// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../ERC721TrustlessFilter.sol";

contract ERC721TrustlessFilterMock is ERC721TrustlessFilter {
    using BitMaps for BitMaps.BitMap;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function getVote(address operator, uint256 tokenId) public view returns (bool) {
        VoteInfo storage operatorVote = _voteInfo[operator];
        bool previouslyAllow = operatorVote.allowVotes.get(tokenId);
        bool previouslyBlock = operatorVote.blockVotes.get(tokenId);
        if (!previouslyAllow && !previouslyBlock) revert("No vote cast");
        return previouslyAllow && !previouslyBlock;
    }

    function getAllowTotal(address operator) public view returns (uint256) {
        return _voteInfo[operator].allowTotal;
    }

    function getBlockTotal(address operator) public view returns (uint256) {
        return _voteInfo[operator].blockTotal;
    }
}
