// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../SuperComposableYield/implementations/SCYBaseWithRewards.sol";
import "../../interfaces/IQiErc20.sol";
import "../../interfaces/IBenQiComptroller.sol";
import "../../interfaces/IWETH.sol";

contract PendleBenQiErc20SCY is SCYBaseWithRewards {
    using SafeERC20 for IERC20;

    address public immutable underlying;
    address public immutable QI;
    address public immutable WAVAX;
    address public immutable comptroller;
    address public immutable qiToken;

    uint256 public override exchangeRateStored;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __sharesdecimals,
        uint8 __assetDecimals,
        bytes32 __assetId,
        address _underlying,
        address _qiToken,
        address _comptroller,
        address _QI,
        address _WAVAX
    ) SCYBaseWithRewards(_name, _symbol, __sharesdecimals, __assetDecimals, __assetId) {
        require(
            _qiToken != address(0) &&
                _QI != address(0) &&
                _WAVAX != address(0) &&
                _comptroller != address(0),
            "zero address"
        );
        qiToken = _qiToken;
        QI = _QI;
        WAVAX = _WAVAX;
        comptroller = _comptroller;
        underlying = _underlying;
        IERC20(underlying).safeIncreaseAllowance(qiToken, type(uint256).max);
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address tokenIn, uint256 amount)
        internal
        override
        returns (uint256 amountSharesOut)
    {
        uint256 amountQiToken;
        if (tokenIn == underlying) {
            // convert it into qiToken first
            uint256 preBalanceQiToken = IERC20(qiToken).balanceOf(address(this));

            uint256 errCode = IQiErc20(qiToken).mint(amount);
            require(errCode == 0, "mint failed");

            amountQiToken = IERC20(qiToken).balanceOf(address(this)) - preBalanceQiToken;
        }

        amountSharesOut = amountQiToken;
    }

    function _redeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        override
        returns (uint256 amountBaseOut)
    {
        if (tokenOut == qiToken) {
            amountBaseOut = amountSharesToRedeem;
        } else {
            uint256 errCode = IQiErc20(qiToken).redeem(amountSharesToRedeem);
            require(errCode == 0, "redeem failed");

            amountBaseOut = IERC20(underlying).balanceOf(address(this));
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() public override returns (uint256) {
        uint256 res = IQiToken(qiToken).exchangeRateCurrent();

        exchangeRateStored = res;
        emit UpdateExchangeRate(res);

        return exchangeRateStored;
    }

    function getRewardTokens() public view override returns (address[] memory res) {
        res = new address[](2);
        res[0] = QI;
        res[1] = WAVAX;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseTokens() public view override returns (address[] memory res) {
        res = new address[](2);
        res[0] = qiToken;
        res[1] = underlying;
    }

    function getReserveTokens() public view override returns (address[] memory res) {
        res = new address[](1);
        res[0] = qiToken;
    }

    function isValidBaseToken(address token) public view override returns (bool res) {
        res = (token == underlying || token == qiToken);
    }

    function _isValidReserveToken(address token) internal view override returns (bool res) {
        res = (token == qiToken);
    }

    function underlyingYieldToken() external view override returns (address) {
        return qiToken;
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function _redeemExternalReward() internal override {
        address[] memory holders = new address[](1);
        address[] memory qiTokens = new address[](1);
        holders[0] = address(this);
        qiTokens[0] = qiToken;

        IBenQiComptroller(comptroller).claimReward(0, holders, qiTokens, false, true);
        IBenQiComptroller(comptroller).claimReward(1, holders, qiTokens, false, true);

        if (address(this).balance != 0) IWETH(WAVAX).deposit{ value: address(this).balance };
    }
}
