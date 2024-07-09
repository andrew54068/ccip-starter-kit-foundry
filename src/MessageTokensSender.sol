// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Withdraw} from "./utils/Withdraw.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */
contract MessageTokensSender is Withdraw {
    using SafeERC20 for IERC20;

    enum PayFeesIn {
        Native,
        LINK
    }

    address immutable i_router;
    address immutable i_link;

    event MessageSent(bytes32 messageId);

    constructor(address router, address link) {
        i_router = router;
        i_link = link;
    }

    function sendBatch(
        uint64 destChainSelector,
        address receiver,
        Client.EVMTokenAmount[] memory tokensToSendDetails
    ) external payable returns (bytes32[] memory messageIds) {
        uint256 length = tokensToSendDetails.length;
        messageIds = new bytes32[](length);
        for (uint256 i = 0; i < length; ) {
            Client.EVMTokenAmount[]
                memory tempDetails = new Client.EVMTokenAmount[](1);
            tempDetails[0] = tokensToSendDetails[i];
            messageIds[i] = send(
                destChainSelector,
                receiver,
                string.concat("0x2Cf26fb0", Strings.toString(i)),
                tempDetails,
                200000,
                PayFeesIn.Native
            );

            unchecked {
                ++i;
            }
        }
    }

    function send(
        uint64 destinationChainSelector,
        address receiver,
        string memory messageText,
        Client.EVMTokenAmount[] memory tokensToSendDetails,
        uint256 gasLimit,
        PayFeesIn payFeesIn
    ) public payable returns (bytes32 messageId) {
        uint256 length = tokensToSendDetails.length;

        for (uint256 i = 0; i < length; ) {
            IERC20(tokensToSendDetails[i].token).safeTransferFrom(
                msg.sender,
                address(this),
                tokensToSendDetails[i].amount
            );
            IERC20(tokensToSendDetails[i].token).approve(
                i_router,
                tokensToSendDetails[i].amount
            );

            unchecked {
                ++i;
            }
        }

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(messageText),
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit
                Client.EVMExtraArgsV1({gasLimit: gasLimit})
            ),
            feeToken: payFeesIn == PayFeesIn.LINK ? i_link : address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

        if (payFeesIn == PayFeesIn.LINK) {
            LinkTokenInterface(i_link).approve(i_router, fee);
            messageId = IRouterClient(i_router).ccipSend(
                destinationChainSelector,
                message
            );
        } else {
            messageId = IRouterClient(i_router).ccipSend{value: fee}(
                destinationChainSelector,
                message
            );
        }

        emit MessageSent(messageId);
    }

    fallback() external payable {}

    receive() external payable {}
}
