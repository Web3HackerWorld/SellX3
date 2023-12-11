// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFTContainer is ERC721, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 private _nextTokenId;

    struct OriginInfo {
        string contractName;
        address nftAddress;
        uint tokenId;
    }

    mapping(uint => OriginInfo) originInfoMap;

    constructor(
        address defaultAdmin,
        address minter
    ) ERC721("NFTContainer", "NFTC") {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
    }

    function safeMint(
        address to,
        string memory contractName,
        address nftAddress,
        uint _tokenId,
        string memory uri
    ) public onlyRole(MINTER_ROLE) returns (uint) {
        uint256 tokenId = _nextTokenId++;
        originInfoMap[tokenId] = OriginInfo(contractName, nftAddress, _tokenId);

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
