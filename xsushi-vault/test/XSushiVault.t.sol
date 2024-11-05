// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/XSushiVault.sol";
import "../src/MockERC20.sol";

contract XSushiVaultTest is Test {
    XSushiVault public vault;
    IERC20 public sushi;
    IERC20 public xSushi;
    ISushiBar public sushiBar;
    ISwapRouter public sushiSwapRouter;
    IERC20 public weth;

    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant SUSHI_ADDRESS = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public constant XSUSHI_ADDRESS = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;
    address public constant SUSHI_BAR_ADDRESS = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;
    address public constant SUSHISWAP_ROUTER_ADDRESS = 0x2E6cd2d30aa43f40aa81619ff4b6E0a41479B13F;

    address public constant USER = address(0x1);
    uint256 public constant INITIAL_BALANCE = 1000e18;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("tenderly"));
        vault = new XSushiVault(SUSHI_ADDRESS, XSUSHI_ADDRESS, SUSHI_BAR_ADDRESS, SUSHISWAP_ROUTER_ADDRESS);
        sushi = IERC20(SUSHI_ADDRESS);
        xSushi = IERC20(XSUSHI_ADDRESS);
        sushiBar = ISushiBar(SUSHI_BAR_ADDRESS);
        sushiSwapRouter = ISwapRouter(SUSHISWAP_ROUTER_ADDRESS);
        weth = IERC20(WETH_ADDRESS);
        deal(WETH_ADDRESS, USER, INITIAL_BALANCE);
        deal(SUSHI_ADDRESS, USER, INITIAL_BALANCE);
    }

    function testDepositXSushi() public {
        uint256 depositAmount = 100e18;
        vm.startPrank(USER);
        sushi.approve(address(sushiBar), depositAmount);
        sushiBar.enter(depositAmount);
        uint256 xSushiBalance = xSushi.balanceOf(USER);
        xSushi.approve(address(vault), xSushiBalance);
        vault.depositXSushi(xSushiBalance);
        vm.stopPrank();
        assertEq(vault.balanceOf(USER), xSushiBalance, "Incorrect vault token balance");
    }

    function testZapIn() public {
        uint256 zapAmount = 1 ether;
        uint256 minSushiOut = 1e18;
        uint24 fee = 3000;

        vm.startPrank(USER);
        weth.approve(address(vault), zapAmount);
        vault.zapIn(WETH_ADDRESS, zapAmount, minSushiOut, fee);
        vm.stopPrank();

        assertGt(vault.balanceOf(USER), 0, "User should have vault tokens");
    }

    function testZapOut() public {
        testZapIn();
        uint256 vaultBalance = vault.balanceOf(USER);
        uint256 minWethOut = 0.5 ether;
        uint24 fee = 3000;

        vm.startPrank(USER);
        vault.zapOut(WETH_ADDRESS, vaultBalance, minWethOut, fee);
        vm.stopPrank();

        assertEq(vault.balanceOf(USER), 0, "User should have no vault tokens left");
        assertGt(weth.balanceOf(USER), minWethOut, "User should have received WETH tokens");
    }

    function testDepositZeroXSushi() public {
        vm.startPrank(USER);
        vm.expectRevert("Cannot deposit 0");
        vault.depositXSushi(0);
        vm.stopPrank();
    }

    function testWithdrawZeroXSushi() public {
        vm.startPrank(USER);
        vm.expectRevert("Cannot withdraw 0");
        vault.withdrawXSushi(0);
        vm.stopPrank();
    }

    function testZapInWithInsufficientAllowance() public {
        uint256 zapAmount = 1 ether;
        uint256 minSushiOut = 1e18;
        uint24 fee = 3000;

        vm.startPrank(USER);
        weth.approve(address(vault), zapAmount - 1);
        vm.expectRevert();
        vault.zapIn(WETH_ADDRESS, zapAmount, minSushiOut, fee);
        vm.stopPrank();
    }

    function testZapInWithZeroAmount() public {
        uint256 minSushiOut = 1e18;
        uint24 fee = 3000;

        vm.startPrank(USER);
        vm.expectRevert("Cannot zap in 0");
        vault.zapIn(WETH_ADDRESS, 0, minSushiOut, fee);
        vm.stopPrank();
    }

    function testZapOutWithZeroAmount() public {
        uint24 fee = 3000;

        vm.startPrank(USER);
        vm.expectRevert("Cannot zap out 0");
        vault.zapOut(WETH_ADDRESS, 0, 0, fee);
        vm.stopPrank();
    }

    function testZapOutWithInvalidToken() public {
        testZapIn();
        uint256 vaultBalance = vault.balanceOf(USER);
        uint24 fee = 3000;

        MockERC20 invalidToken = new MockERC20("Invalid", "INV");

        vm.startPrank(USER);
        vm.expectRevert();
        vault.zapOut(address(invalidToken), vaultBalance, 0, fee);
        vm.stopPrank();
    }

    function testZapInWithHighSlippage() public {
        uint256 zapAmount = 1 ether;
        uint256 unrealisticallyHighMinSushiOut = 1000000e18;
        uint24 fee = 3000;

        vm.startPrank(USER);
        weth.approve(address(vault), zapAmount);
        vm.expectRevert("Too little received");

        vault.zapIn(WETH_ADDRESS, zapAmount, unrealisticallyHighMinSushiOut, fee);
        vm.stopPrank();
    }

    function testZapOutWithHighSlippage() public {
        testZapIn();
        uint256 vaultBalance = vault.balanceOf(USER);
        uint256 unrealisticallyHighMinWethOut = 1000000e18;
        uint24 fee = 3000;

        vm.startPrank(USER);
        vm.expectRevert("Too little received");

        vault.zapOut(WETH_ADDRESS, vaultBalance, unrealisticallyHighMinWethOut, fee);
        vm.stopPrank();
    }

    function testDepositXSushiMintedAmount() public {
        uint256 depositAmount = 100e18;
        vm.startPrank(USER);
        sushi.approve(address(sushiBar), depositAmount);
        sushiBar.enter(depositAmount);
        uint256 xSushiBalance = xSushi.balanceOf(USER);
        xSushi.approve(address(vault), xSushiBalance);

        uint256 preVaultBalance = vault.balanceOf(USER);
        vault.depositXSushi(xSushiBalance);
        uint256 postVaultBalance = vault.balanceOf(USER);

        vm.stopPrank();

        uint256 mintedAmount = postVaultBalance - preVaultBalance;
        assertEq(mintedAmount, xSushiBalance, "Minted amount should equal deposited xSUSHI amount");
    }

    function testZapInMintedAmount() public {
        uint256 zapAmount = 1 ether;
        uint256 minSushiOut = 1e18;
        uint24 fee = 3000;

        vm.startPrank(USER);
        weth.approve(address(vault), zapAmount);

        uint256 preVaultBalance = vault.balanceOf(USER);
        vault.zapIn(WETH_ADDRESS, zapAmount, minSushiOut, fee);
        uint256 postVaultBalance = vault.balanceOf(USER);

        vm.stopPrank();

        uint256 mintedAmount = postVaultBalance - preVaultBalance;
        assertGt(mintedAmount, 0, "Minted amount should be greater than 0");

        // Calculate expected xSUSHI amount
        uint256 expectedXSushiAmount = xSushi.balanceOf(address(vault));
        assertEq(mintedAmount, expectedXSushiAmount, "Minted amount should equal received xSUSHI amount");
    }
}
