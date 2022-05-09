// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../SuperComposableYield/implementations/SCYBase.sol";
import "../../interfaces/IYearnVault.sol";
import "../../interfaces/IQiErc20.sol";

contract PendleYearnVaultScy is SCYBase {
    using SafeERC20 for IERC20;

    address public immutable underlying;
    address public immutable yvToken;
    address public cToken;

    uint256 public override exchangeRateStored;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __scydecimals,
        uint8 __assetDecimals,
        bytes32 __assetId,
        address _underlying,
        address _yvToken
    ) SCYBase(_name, _symbol, __scydecimals, __assetDecimals, __assetId) {
        require(_yvToken != address(0), "zero address");
        yvToken = _yvToken;
        underlying = _underlying;
        IERC20(underlying).safeIncreaseAllowance(yvToken, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _toUnderlyingYieldToken(address token, uint256 amountBase)
        internal
        virtual
        override
        returns (uint256 amountScyOut)
    {
        if (token == yvToken) {
            amountScyOut = amountBase;
        } else if (token == cToken || token == underlying) {
            uint256 amountUnderlying;
            if (token == cToken) {
                uint256 successful = IQiErc20(cToken).redeem(amountBase);
                require(successful == 0, "redeem failed");
                amountUnderlying = IERC20(underlying).balanceOf(address(this));
            }
            uint256 preBalance = IERC20(yvToken).balanceOf(address(this));
            IYearnVault(yvToken).deposit(amountBase);
            amountScyOut = IERC20(yvToken).balanceOf(address(this)) - preBalance; // 1 yvToken = 1 SCY
        }
    }

    function _toBaseToken(address token, uint256 amountScy)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (token == yvToken) {
            amountTokenOut = amountScy;
        } else {
            // token == underlying
            IYearnVault(yvToken).withdraw(amountScy);
            amountTokenOut = IERC20(underlying).balanceOf(address(this));
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() public virtual override returns (uint256) {
        uint256 res = IYearnVault(yvToken).pricePerShare();

        exchangeRateStored = res;
        emit UpdateExchangeRate(res);

        return res;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseTokens() public view virtual override returns (address[] memory res) {
        res = new address[](3);
        res[0] = underlying;
        res[1] = yvToken;
        res[2] = cToken;
        // SCY-yvToken
    }

    function isValidBaseToken(address token) public view virtual override returns (bool) {
        return token == underlying || token == yvToken;
    }

    function underlyingYieldToken() external view virtual override returns (address) {
        return yvToken;
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    //solhint-disable-next-line no-empty-blocks
    function harvest(address user) public virtual override returns (uint256[] memory) {}

    function getRewardTokens() public view virtual override returns (address[] memory res) {
        res = new address[](0);
    }

    //solhint-disable-next-line no-empty-blocks
    function _redeemExternalReward() internal virtual {}
}
