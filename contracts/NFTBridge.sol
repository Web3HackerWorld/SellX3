// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface INFTContainer is IERC721 {
    function safeMint(
        address to,
        string memory contractName,
        address nftAddress,
        uint _tokenId,
        string memory uri
    ) external returns (uint);
}

contract NFTBridge is CCIPReceiver, OwnerIsCreator {
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        address nftAddress,
        uint256 tokenId,
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );

    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        address nftAddress,
        uint tokenId,
        string tokenURI,
        string contractName
    );

    mapping(uint64 => mapping(address => address)) bridgeMap; // chainSelector.sourceTokenAddress.targetTokenAddress

    IRouterClient private s_router;
    LinkTokenInterface private s_linkToken;

    constructor(address _router, address _link) CCIPReceiver(_router) {
        s_router = IRouterClient(_router);
        s_linkToken = LinkTokenInterface(_link);
    }

    function withdrawLinkAndETH()
        public
        onlyOwner
        returns (bool send1, bool send2)
    {
        uint256 amount1 = address(this).balance;
        address owner = msg.sender;
        if (amount1 > 0) {
            (send1, ) = owner.call{value: amount1}("");
        }

        uint256 amount2 = s_linkToken.balanceOf(address(this));
        if (amount2 > 0) {
            send2 = s_linkToken.transfer(owner, amount2);
        }
    }

    receive() external payable {}

    function bridgeNFT(
        uint64 _destinationChainSelector,
        address _receiver,
        address _nftAddress,
        uint256 _tokenId
    ) external payable returns (bytes32 messageId) {
        string memory contractName = IERC721Metadata(_nftAddress).name();
        string memory _tokenURI = IERC721Metadata(_nftAddress).tokenURI(
            _tokenId
        );
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: abi.encode(_nftAddress, _tokenId, _tokenURI, contractName), // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: address(s_linkToken)
        });

        uint fees = s_router.getFee(_destinationChainSelector, evm2AnyMessage);

        IERC721(_nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        s_linkToken.approve(address(s_router), fees);
        messageId = s_router.ccipSend(
            _destinationChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(
            messageId,
            _destinationChainSelector,
            _receiver,
            _nftAddress,
            _tokenId,
            address(s_linkToken),
            fees
        );

        return messageId;
    }

    address nftContainerAddress;
    mapping(address => mapping(uint => uint)) nftToContainerMap;

    function updateContainerAddress(
        address _containerAddress
    ) public onlyOwner {
        nftContainerAddress = _containerAddress;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        address sender = abi.decode(any2EvmMessage.sender, (address));
        (
            address nftAddress,
            uint256 tokenId,
            string memory tokenURI,
            string memory contractName
        ) = abi.decode(any2EvmMessage.data, (address, uint256, string, string));

        if (nftToContainerMap[nftAddress][tokenId] == 0) {
            uint containerNFTId = INFTContainer(nftContainerAddress).safeMint(
                sender,
                contractName,
                nftAddress,
                tokenId,
                tokenURI
            );
            nftToContainerMap[nftAddress][tokenId] = containerNFTId;
        } else {
            INFTContainer(nftContainerAddress).safeTransferFrom(
                address(this),
                sender,
                nftToContainerMap[nftAddress][tokenId]
            );
        }

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector, // fetch the source chain identifier (aka selector)
            sender, // abi-decoding of the sender address,
            nftAddress,
            tokenId,
            tokenURI,
            contractName
        );
    }
}
