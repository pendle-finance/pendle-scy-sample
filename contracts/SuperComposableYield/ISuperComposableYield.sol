// SPDX-License-Identifier: GPL-3.0-or-later
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ISuperComposableYield is IERC20Metadata {
    event NewExchangeRate(uint256 exchangeRate);
    event Deposit(
        address indexed caller,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountDeposited,
        uint256 amountScyOut
    );

    event Redeem(
        address indexed caller,
        address indexed receiver,
        address indexed tokenOut,
        uint256 amountScyToRedeem,
        uint256 amountTokenOut
    );

    event Harvests(address indexed user, address[] rewardTokens, uint256[] rewardAmounts);

    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToPull,
        uint256 minScyOut
    ) external returns (uint256 amountScyOut);

    function redeem(
        address receiver,
        uint256 amountScyToPull,
        address tokenOut,
        uint256 minTokenOut
    ) external returns (uint256 amountTokenOut);

    function harvest(address user) external returns (uint256[] memory rewardAmounts);

    /**
    * @notice exchangeRateCurrent * scyBalance / 1e18 must return the asset balance of the account
    * @notice vice-versa, if a user uses some amount of tokens equivalent to X asset, the amount of scy
    he can mint must be X * exchangeRateCurrent / 1e18
    * @dev SCYUtils's assetToScy & scyToAsset should be used instead of raw multiplication
    & division
    */
    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function yieldToken() external view returns (address);

    function getBaseTokens() external view returns (address[] memory);

    function isValidBaseToken(address token) external view returns (bool);

    function getRewardTokens() external view returns (address[] memory);

    function assetDecimals() external view returns (uint8);

    function assetId() external view returns (bytes32);
}
