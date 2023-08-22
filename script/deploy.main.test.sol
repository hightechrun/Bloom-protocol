// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Script, console2} from "forge-std/Script.sol";
import {LibRLP} from "solady/utils/LibRLP.sol";

import {MerkleWhitelist} from "../src/MerkleWhitelist.sol";
import {BPSFeed} from "../src/BPSFeed.sol";
import {BloomPool} from "../src/BloomPool.sol";
import {SwapFacility} from "../src/SwapFacility.sol";

import {ISwapFacility} from "../src/interfaces/ISwapFacility.sol";
import {IWhitelist} from "../src/interfaces/IWhitelist.sol";

contract Deploy is Test, Script {
    address internal constant TREASURY = 0xFdC004B6B92b45B224d37dc45dBA5cA82c1e08f2;
    address internal constant EMERGENCY_HANDLER = 0x989B1a8EefaC6bF66a159621D49FaF4A939b452D;

    address internal constant UNDERLYING_TOKEN = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
    address internal constant BILL_TOKEN = 0xCA30c93B02514f86d5C86a6e375E3A330B435Fb5; //bIB01

    // chainlink feeds
    address internal constant USDCUSD = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address internal constant IB01USD = 0x32d1463EB53b73C095625719Afa544D5426354cB;

    address internal constant SWAP = 0x4D47C6e6315178ec28C61A9C73CEcec651B1d837;
    address internal constant BPSFEED = 0x51fD7269fD752C62E75E990DbBe73BaDf97924AD;
    IWhitelist internal constant WHITELIST = IWhitelist(0x30B4a5f5f98dbcAd5A76Db9328dA48057CEFD5F4);

    bytes32 internal constant INITIALROOT = 0xabc6a38afc2e6c26bad45002703dd3bae47e41d24d13e71f8e61687633acc2ea;
    address internal constant INITIALOWNER = 0x3031303BB07C35d489cd4B7E6cCd6Fb16eA2b3a1;

    uint256 internal constant SPREAD = 0.0125e4; // 0.125%
    uint256 internal constant MIN_STABLE_VALUE = 0.999e8;
    uint256 internal constant MAX_BILL_VALUE = 107.6e8;
    uint256 internal constant BPS = 1e4;
    uint256 internal constant commitPhaseDuration = 1 hours;
    uint256 internal constant poolPhaseDuration = 2 hours;
    uint256 internal constant preHoldSwapTimeout = 7 days;

    // Aux
    BPSFeed internal lenderReturnBpsFeed;
    MerkleWhitelist internal whitelist;

    // Protocol
    BloomPool internal pool;
    //SwapFacility internal swap;

    function run() public {
        vm.startBroadcast();

        // Deploy aux items
        //_deployMerkleWhitelist();
        //_deployBPSFeed();

        // Deploy protocol
        //_deploySwapFacility();
        _deployBloomPool();

        vm.stopBroadcast();
    }

    //function _deployMerkleWhitelist() internal {
    //    whitelist = new MerkleWhitelist(
    //        INITIALROOT,
    //        INITIALOWNER
    //    );
    //    vm.label(address(whitelist), "MerkleWhitelist");
    //    console2.log("MerkleWhitelist deployed at:", address(whitelist));
    //}

    //function _deployBPSFeed() internal {
    //    lenderReturnBpsFeed = new BPSFeed();
    //    vm.label(address(lenderReturnBpsFeed), "BPSFeed");
    //    console2.log("BPSFeed deployed at:", address(lenderReturnBpsFeed));
    //}

    //function _deploySwapFacility() internal {
    //    uint256 deployerNonce = vm.getNonce(msg.sender);

    //    swap = new SwapFacility(
    //        UNDERLYING_TOKEN, 
    //        BILL_TOKEN,
    //        USDCUSD,
    //        IB01USD,
    //        IWhitelist(address(WHITELIST)),
    //        //IWhitelist(address(whitelist)),
    //        SPREAD,
    //        LibRLP.computeAddress(msg.sender, deployerNonce + 1),
    //        MIN_STABLE_VALUE,
    //        MAX_BILL_VALUE
    //    );
    //    vm.label(address(swap), "SwapFacility");
    //    console2.log("SwapFacility deployed at:", address(swap));
    //}

    function _deployBloomPool() internal {
        pool = new BloomPool(
            UNDERLYING_TOKEN,
            BILL_TOKEN,
            IWhitelist(address(WHITELIST)),
            //IWhitelist(address(whitelist)),
            SWAP,
            //address(swap),
            TREASURY,
            BPSFEED,
            //address(lenderReturnBpsFeed),
            EMERGENCY_HANDLER,
            50e4,
            1,
            commitPhaseDuration,
            preHoldSwapTimeout,
            poolPhaseDuration,
            300, // 3%
            0, // 30%
            "Term Bound Yield Test",
            "TBY-Test"
        );
        console2.log("BloomPool deployed at:", address(pool));
    }
}