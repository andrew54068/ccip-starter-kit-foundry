// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {MessageTokenSender} from "../src/MessageTokenSender.sol";

contract DeployMessageTokenSender is Script, Helper {
    function run(SupportedNetworks source) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (address router, address link, , ) = getConfigFromNetwork(source);

        MessageTokenSender messageTokenSender = new MessageTokenSender(
            router,
            link
        );

        console.log(
            "MessageTokenSender contract deployed on ",
            networks[source],
            "with address: ",
            address(messageTokenSender)
        );

        vm.stopBroadcast();
    }
}

contract SendMessage is Script, Helper {
    function run(
        address payable sender,
        SupportedNetworks destination,
        address receiver,
        string memory message,
        MessageTokenSender.PayFeesIn payFeesIn
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);

        address transferTokenAddress = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d; // USDC

        bytes32[] memory messageIds = MessageTokenSender(sender).sendBatch(
            destinationChainId,
            receiver,
            transferTokenAddress
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
