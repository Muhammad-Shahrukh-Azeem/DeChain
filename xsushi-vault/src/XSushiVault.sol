// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

interface ISushiBar {
    function enter(uint256 amount) external;
    function leave(uint256 share) external;
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract XSushiVault is ERC4626, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ISushiBar public immutable sushiBar;
    ISwapRouter public immutable sushiSwapRouter;
    IERC20 public immutable sushi;
    IERC20 public immutable xSushi;

    constructor(address _sushi, address _xSushi, address _sushiBar, address _sushiSwapRouter)
        ERC4626(IERC20(_xSushi))
        ERC20("XSushi Vault", "xSUSHI-VLT")
    {
        sushi = IERC20(_sushi);
        xSushi = IERC20(_xSushi);
        sushiBar = ISushiBar(_sushiBar);
        sushiSwapRouter = ISwapRouter(_sushiSwapRouter);
    }

    function depositXSushi(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot deposit 0");
        xSushi.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function withdrawXSushi(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        _burn(msg.sender, amount);
        xSushi.safeTransfer(msg.sender, amount);
    }

    function zapIn(address token, uint256 amount, uint256 minSushiOut, uint24 fee) external nonReentrant {
        require(amount > 0, "Cannot zap in 0");
        require(token != address(xSushi), "Use depositXSushi for xSushi");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(address(sushiSwapRouter), amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: token,
            tokenOut: address(sushi),
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: minSushiOut,
            sqrtPriceLimitX96: 0
        });

        uint256 sushiReceived = sushiSwapRouter.exactInputSingle(params);

        sushi.approve(address(sushiBar), sushiReceived);
        sushiBar.enter(sushiReceived);

        uint256 xSushiReceived = xSushi.balanceOf(address(this));
        _mint(msg.sender, xSushiReceived);
    }

    function zapOut(address token, uint256 shareAmount, uint256 minTokenOut, uint24 fee) external nonReentrant {
        require(shareAmount > 0, "Cannot zap out 0");

        _burn(msg.sender, shareAmount);

        uint256 xSushiAmount = xSushi.balanceOf(address(this));
        xSushi.approve(address(sushiBar), xSushiAmount);
        sushiBar.leave(xSushiAmount);

        uint256 sushiAmount = sushi.balanceOf(address(this));

        if (token == address(sushi)) {
            sushi.safeTransfer(msg.sender, sushiAmount);
            return;
        }

        sushi.approve(address(sushiSwapRouter), sushiAmount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(sushi),
            tokenOut: token,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: sushiAmount,
            amountOutMinimum: minTokenOut,
            sqrtPriceLimitX96: 0
        });

        uint256 tokenReceived = sushiSwapRouter.exactInputSingle(params);
        require(tokenReceived >= minTokenOut, "Insufficient output amount");
    }
}
