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
    /// @dev May be emitted when the SCY exchangeRate is updated
    event NewExchangeRate(uint256 exchangeRate);

    /// @dev Emitted when any base tokens is deposited to mint SCY tokens
    event Deposit(
        address indexed caller,
        address indexed receiver,
        address indexed tokenIn,
        uint256 amountDeposited,
        uint256 amountScyOut
    );

    /// @dev Emitted when any SCY tokens are redeemed for base tokens
    event Redeem(
        address indexed caller,
        address indexed receiver,
        address indexed tokenOut,
        uint256 amountScyToRedeem,
        uint256 amountTokenOut
    );

    /// @dev Emitted when (`user`) claims rewards
    event ClaimRewardss(address indexed user, address[] rewardTokens, uint256[] rewardAmounts);

    /**
     * @notice mints an amount of SCY tokens by depositing a base token.
     * @param receiver - address of the SCY token recipient
     * @param tokenIn - address of the deposited base token
     * @param amountTokenToPull - amount of base tokens to be deposited using the allowance mechanism
     * @param minSharesOut - minimum amount of SCY to be minted
     * @return amountSharesOut - amount of SCY tokens minted
     * @dev 
     *
     * There are two ways to deposit a base token:
     * - The tokens should have been transferred directly to this contract, prior to calling.
     * - An allowance of at least `amountTokenToPull` for this contract is made by the caller. 
     * Then calling this function with the corresponding `amountTokenToPull` will allow the
     * contract to transfer said amount of base tokens to itself.
     *
     * The amount of SCY tokens minted will be based on the combined amount of base tokens newly 
     * deposited using the given two methods.
     *
     * Emits a {Deposit} event
     * 
     * Requirements:
     * - (`baseTokenIn`) must be a valid base token.
     * - If `amountTokenToPull` is a non-zero value, there must be an ongoing approval from (`msg.sender`)
     * for this contract with at least `amountTokenToPull` base tokens.
     * - `minSharesOut` must be sufficiently small (such that at least said amount of SCY can be minted)
     */
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToPull,
        uint256 minSharesOut
    ) external returns (uint256 amountSharesOut);

    /**
     * @notice redeems an amount of base tokens by burning some amount of SCY tokens
     * @param receiver - address of the base token recipient
     * @param amountSharesToPull - amount of SCY tokens to be deposited using the allowance mechanism
     * @param tokenOut - address of the base token to be redeemed
     * @param minTokenOut - minimum amount of base tokens to be redeemed
     * @return amountTokenOut - amount of base tokens redeemed
     * @dev 
     *
     * There are two ways to deposit SCY tokens:
     * - The SCY tokens should have been transferred directly to this contract, prior to calling.
     * - An allowance of at least `amountSharesToPull` for this contract is made by the caller. 
     * Then calling this function with the corresponding `amountSharesToPull` will allow the
     * contract to transfer said amount of base tokens to itself.
     *
     * All of the SCY deposited using the given two methods will be burned to redeem base tokens for
     * (`receiver`). This also implies that the only time this contract holds its own token is when this 
     * function is called.
     *
     * Emits a {Redeem} event
     * 
     * Requirements:
     * - (`tokenOut`) must be a valid base token.
     * - If `amountSharesToPull` is a non-zero value, there must be an ongoing approval from (`msg.sender`)
     * for this contract with at least `amountSharesToPull` SCY tokens.
     * - `minTokenOut` must be sufficiently small (such that at least said amount of tokens can be redeemed)
     */
    function redeem(
        address receiver,
        uint256 amountSharesToPull,
        address tokenOut,
        uint256 minTokenOut
    ) external returns (uint256 amountTokenOut);

    /**
     * @notice exchangeRateCurrent * scyBalance / 1e18 must return the asset balance of the account
     * @notice vice-versa, if a user uses some amount of tokens equivalent to X asset, the amount of scy
     he can mint must be X * exchangeRateCurrent / 1e18
     * @dev SCYUtils's assetToScy & scyToAsset should be used instead of raw multiplication
     & division
     * 
     * May emit a {NewExchangeRate} event
     */
    function exchangeRateCurrent() external returns (uint256 res);

    /**
     * @notice returns the previously updated and stored SCY exchange rate
     * @dev the returned value may be outdated if exchangeRateCurrent() was not called for a
     * extended period of time
     */
    function exchangeRateStored() external view returns (uint256 res);

    /**
     * @notice transfers reward tokens to the user claiming
     * @param user - address of the user claiming rewards
     * @return rewardAmounts - an array with the same length as the number of reward 
     * tokens, denoting the amount of each corresponding reward tokens
     * @dev 
     * Emits a `ClaimRewardss` event
     * See {getRewardTokens} for list of reward tokens
     */
    function claimRewards(address user) external returns (uint256[] memory rewardAmounts);

    /**
     * @notice returns the list of reward token addresses
     */
    function getRewardTokens() external view returns (address[] memory);

    /**
     * @notice returns the address of the underlying yield token
     */
    function yieldToken() external view returns (address);

    /**
     * @notice returns a list of all the base tokens that can be deposited to mint SCY
     */
    function getBaseTokens() external view returns (address[] memory res);

    /**
     * @notice checks whether a token is a valid base token
     * @notice returns a boolean indicating whether this is a valid token 
     */
    function isValidBaseToken(address token) external view returns (bool);

    /**
     * @notice returns the decimals used to get the SCY's user representation
     */
    function assetDecimals() external view returns (uint8);

    function assetId() external view returns (bytes32);
}
