// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../../implementations/SCYBaseWithRewards.sol";
import "../../../interfaces/IAToken.sol";
import "../../../interfaces/IAavePool.sol";
import "../../../interfaces/IAaveRewardsController.sol";
import "./WadRayMath.sol";

contract PendleAaveV3SCY is SCYBaseWithRewards {
    using Math for uint256;
    using WadRayMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable underlying;
    address public immutable pool;
    address public immutable rewardsController;
    address public immutable aToken;

    uint256 public override exchangeRateStored;
    uint256 public constant PRECISION_INDEX = 1e9;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __scydecimals,
        uint8 __assetDecimals,
        bytes32 __assetId,
        address _aavePool,
        address _underlying,
        address _aToken,
        address _rewardsController
    ) SCYBaseWithRewards(_name, _symbol, __scydecimals, __assetDecimals, __assetId) {
        aToken = _aToken;
        pool = _aavePool;
        underlying = _underlying;
        rewardsController = _rewardsController;
        IERC20(underlying).safeIncreaseAllowance(pool, type(uint256).max);
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
        // aTokenScaled -> scy is 1:1
        if (token == aToken) {
            amountScyOut = _aTokenToScaledBalance(amountBase);
        } else {
            uint256 preScaledBalance = IAToken(aToken).scaledBalanceOf(address(this));
            IAavePool(pool).supply(underlying, amountBase, address(this), 0);
            amountScyOut = IAToken(aToken).scaledBalanceOf(address(this)) - preScaledBalance;
        }
    }

    function _toBaseToken(address token, uint256 amountScy)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (token == aToken) {
            amountTokenOut = _scaledBalanceToAToken(amountScy);
        } else {
            uint256 amountATokenToWithdraw = _scaledBalanceToAToken(amountScy);
            IAavePool(pool).withdraw(underlying, amountATokenToWithdraw, address(this));
            amountTokenOut = IERC20(underlying).balanceOf(address(this));
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() public virtual override returns (uint256) {
        uint256 res = _getReserveNormalizedIncome() / PRECISION_INDEX;

        exchangeRateStored = res;
        emit UpdateExchangeRate(res);

        return res;
    }

    function getRewardTokens() public view override returns (address[] memory res) {
        res = IAaveRewardsController(rewardsController).getRewardsByAsset(aToken);
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseTokens() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = underlying;
        res[1] = aToken;
    }

    function isValidBaseToken(address token) public view virtual override returns (bool res) {
        res = (token == underlying || token == aToken);
    }

    function underlyingYieldToken() external view virtual override returns (address) {
        return aToken;
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function _redeemExternalReward() internal override {
        address[] memory assets = new address[](1);
        assets[0] = aToken;

        IAaveRewardsController(rewardsController).claimAllRewards(assets, address(this));
    }

    function _getReserveNormalizedIncome() internal view returns (uint256) {
        return IAavePool(pool).getReserveNormalizedIncome(underlying);
    }

    function _aTokenToScaledBalance(uint256 aTokenAmount) internal view returns (uint256) {
        return aTokenAmount.rayDiv(_getReserveNormalizedIncome());
    }

    function _scaledBalanceToAToken(uint256 scaledAmount) internal view returns (uint256) {
        return scaledAmount.rayMul(_getReserveNormalizedIncome());
    }
}
