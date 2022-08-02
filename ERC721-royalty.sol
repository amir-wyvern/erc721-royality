// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC721 ,ERC721URIStorage ,Pausable, AccessControl, ERC721Burnable ,Ownable , EIP712, ERC721Votes {
    
    using Counters for Counters.Counter;
    
    uint256 public cost = 10**5 wei;

    uint256 public maxSupply = 10000;
    address public artist;
    uint256 public royalityFee;


    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) tokenIdToPower;

    event Sale(address from, address to, uint256 value);

    constructor(address _artist, uint256 _royalityFee) ERC721("MyToken", "MTK") EIP712("MyToken", "1") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        royalityFee = _royalityFee;
        artist = _artist;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _payRoyality(uint256 _royalityFee) internal {
        (bool success, ) = payable(artist).call{value: _royalityFee}("");
        require(success);
    }

    function setRoyalityFee(uint256 _royalityFee) public onlyRole(MINTER_ROLE) {
        royalityFee = _royalityFee;
    }

    function safeMint(address to) public payable onlyRole(MINTER_ROLE) {

        require(_tokenIdCounter.current() <= maxSupply ,"You Can't mint more than maxSupply!");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        tokenIdToPower[tokenId] = 1;
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        require(!paused(), "ERC20Pausable: token transfer while paused");
        
        uint256 royality = (msg.value * royalityFee) / 100;
        _payRoyality(royality);
        (bool success, ) = payable(from).call{value: msg.value - royality}("");
        
        require(success);

        emit Sale(from, to, msg.value);

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Votes)
    {
        _transferVotingUnits(from, to, tokenIdToPower[tokenId]);
        super._afterTokenTransfer(from, to, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function _getVotingUnits(address account) internal view override returns (uint256) {

        uint256 balance = balanceOf(account);

        return balance;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    
}
