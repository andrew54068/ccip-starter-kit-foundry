// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {MessageTokensSender} from "../src/MessageTokensSender.sol";
import {BasicMessageReceiver} from "../src/BasicMessageReceiver.sol";

contract DeployMessageTokensReceiver is Script, Helper {
    function run(address router) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        BasicMessageReceiver basicMessageTokensSender = new BasicMessageReceiver(
                router
            );

        console.log(
            "MessageTokensSender contract deployed on ",
            "Polygon",
            "with address: ",
            address(basicMessageTokensSender)
        );

        vm.stopBroadcast();
    }
}

contract DeployMessageTokensSender is Script, Helper {
    function run(address router) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MessageTokensSender messageTokensSender = new MessageTokensSender(
            router,
            0xf97f4df75117a78c1A5a0DBb814Af92458539FB4 // link address on Arbitrum
        );

        console.log(
            "MessageTokensSender contract deployed on ",
            "Arbitrum",
            "with address: ",
            address(messageTokensSender)
        );

        vm.stopBroadcast();
    }
}

contract SendBatchMessage is Script, Helper {
    function run(
        address payable sender,
        address payable messageTokensSender,
        address receiver,
        MessageTokensSender.PayFeesIn payFeesIn
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        uint64 destinationChainId = 4051577828743386545;

        address usdcAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // arb mainnet USDC
        address betsAddress = 0x94025780a1aB58868D9B2dBBB775f44b32e8E6e5; // arb mainnet BETS

        uint256 usdcBalance = IERC20(usdcAddress).balanceOf(sender);
        uint256 betsBalance = IERC20(betsAddress).balanceOf(sender);
        require(usdcBalance > 0, "USDC balance is 0");
        require(betsBalance > 0, "BETS balance is 0");

        Client.EVMTokenAmount memory usdcToSendDetail = Client.EVMTokenAmount({
            token: usdcAddress,
            amount: 1
        });
        Client.EVMTokenAmount memory betsToSendDetail = Client.EVMTokenAmount({
            token: betsAddress,
            amount: 1
        });
        Client.EVMTokenAmount[] memory tokensToSendDetails = new Client.EVMTokenAmount[](2);
        tokensToSendDetails[0] = betsToSendDetail;
        tokensToSendDetails[1] = usdcToSendDetail;

        IERC20(usdcAddress).approve(messageTokensSender, 6);
        IERC20(betsAddress).approve(messageTokensSender, 6);

        bytes32[] memory messageIds = MessageTokensSender(messageTokensSender).sendBatch{value: 0.0009 ether}(
            destinationChainId,
            receiver,
            tokensToSendDetails
        );

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        for (uint256 i = 0; i < messageIds.length; i++) {
            console.logBytes32(messageIds[i]);
        }

        vm.stopBroadcast();
    }
}
