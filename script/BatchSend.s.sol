// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
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

contract SendBatchMessage is Script, Helper {
    function run(
        address payable sender,
        address payable messageTokenSender,
        address receiver,
        MessageTokenSender.PayFeesIn payFeesIn
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);
        uint64 destinationChainId = 4051577828743386545;

        // address transferTokenAddress = 0x75faf114eafb1BDbe2F0316DF893fd58CE46AA4d; // testnet USDC
        address transferTokenAddress = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85; // mainnet USDC

        IERC20(transferTokenAddress).approve(messageTokenSender, 9);

        sender.call{value: 0.02 ether}("");

        bytes32[] memory messageIds = MessageTokenSender(messageTokenSender).sendBatch{value: 0.02 ether}(
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
