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
     * @dev See {SCYBase-_deposit}
     *  
     * The underlying yield token is yvToken. If the base token deposited is underlying asset, the function 
     * first mints yvToken using those deposited. Then the corresponding amount of shares is returned.
     *
     * The exchange rate of yvToken to shares is 1:1
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
     * @dev See {SCYBase-_redeem}
     * 
     * The shares are redeemed into the same amount of yvTokens. If `tokenOut` is the underlying asset, 
     * the function also withdraws said asset for redemption, using the corresponding amount of yvToken.
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
     * @notice Calculates and updates the exchange rate of shares to underlying asset token
     * @dev It is the price per share of the yvToken
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
