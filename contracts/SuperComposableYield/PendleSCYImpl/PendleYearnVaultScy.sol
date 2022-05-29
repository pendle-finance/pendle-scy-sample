// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../SuperComposableYield/implementations/SCYBase.sol";
import "../../interfaces/IYearnVault.sol";
import "../../interfaces/IQiErc20.sol";

contract PendleYearnVaultSCY is SCYBase {
    using SafeERC20 for IERC20;

    address public immutable underlying;
    address public immutable yvToken;

    uint256 public override exchangeRateStored;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __scydecimals,
        uint8 __assetDecimals,
        bytes32 __assetId,
        address _underlying,
        address _yvToken
    ) SCYBase(_name, _symbol, _yvToken, __scydecimals, __assetDecimals, __assetId) {
        require(_yvToken != address(0), "zero address");
        yvToken = _yvToken;
        underlying = _underlying;
        IERC20(underlying).safeIncreaseAllowance(yvToken, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates amount of SCY shares to be minted, given base token and its amount deposited
     * @dev `tokenIn` is guaranteed to be one of the valid base tokens
     */
    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 amountSharesOut)
    {
        if (tokenIn == yvToken) {
            amountSharesOut = amountDeposited;
        } else if (tokenIn == underlying) {
            uint256 preBalance = IERC20(yvToken).balanceOf(address(this));
            IYearnVault(yvToken).deposit(amountDeposited);
            amountSharesOut = IERC20(yvToken).balanceOf(address(this)) - preBalance; // 1 yvToken = 1 SCY
        }
    }

    /**
     * @notice Calculates amount of tokens to be redeemed, given amount of SCY to be burned
     * @dev `tokenOut` is guaranteed to be one of the valid base tokens
     */
    function _redeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (tokenOut == yvToken) {
            amountTokenOut = amountSharesToRedeem;
        } else {
            // tokenOut == underlying
            IYearnVault(yvToken).withdraw(amountSharesToRedeem);
            amountTokenOut = IERC20(underlying).balanceOf(address(this));
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates and updates the exchange rate of SCY
     * @dev This SCY acts as a wrapper for yvToken, therefore its own price per share suffices
     */
    function exchangeRateCurrent() public virtual override returns (uint256) {
        uint256 res = IYearnVault(yvToken).pricePerShare();

        exchangeRateStored = res;
        emit NewExchangeRate(res);

        return res;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ISuperComposableYield-getBaseTokens}
     */
    function getBaseTokens() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = underlying;
        res[1] = yvToken;
    }

    /**
     * @dev See {ISuperComposableYield-isValidBaseToken}
     */
    function isValidBaseToken(address token) public view virtual override returns (bool) {
        return token == underlying || token == yvToken;
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    //solhint-disable-next-line no-empty-blocks
    function claimRewards(address user) public virtual override returns (uint256[] memory) {}

    function getRewardTokens() public view virtual override returns (address[] memory res) {
        res = new address[](0);
    }
}
