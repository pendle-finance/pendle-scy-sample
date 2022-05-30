// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../SuperComposableYield/implementations/SCYBaseWithRewards.sol";
import "../../interfaces/IQiErc20.sol";
import "../../interfaces/IQiAvax.sol";
import "../../interfaces/IBenQiComptroller.sol";
import "../../interfaces/IWETH.sol";

contract PendleQiTokenSCY is SCYBaseWithRewards {
    address public immutable underlying;
    address public immutable QI;
    address public immutable WAVAX;
    address public immutable comptroller;
    address public immutable qiToken;

    uint256 public override exchangeRateStored;

    constructor(
        string memory _name,
        string memory _symbol,
        address _underlying,
        address _qiToken,
        address _comptroller,
        address _QI,
        address _WAVAX
    ) SCYBaseWithRewards(_name, _symbol, _qiToken) {
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
        if (underlying != NATIVE) {
            _safeApprove(underlying, qiToken, type(uint256).max);
        }
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address tokenIn, uint256 amount)
        internal
        override
        returns (uint256 amountSharesOut)
    {
        if (tokenIn == qiToken) {
            amountSharesOut = amount;
        } else {
            // tokenIn is underlying -> convert it into qiToken first
            uint256 preBalanceQiToken = _selfBalance(qiToken);

            if (underlying == NATIVE) {
                IQiAvax(qiToken).mint{ value: amount }();
            } else {
                uint256 errCode = IQiErc20(qiToken).mint(amount);
                require(errCode == 0, "mint failed");
            }

            amountSharesOut = _selfBalance(qiToken) - preBalanceQiToken;
        }
    }

    function _redeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        override
        returns (uint256 amountBaseOut)
    {
        if (tokenOut == qiToken) {
            amountBaseOut = amountSharesToRedeem;
        } else {
            if (underlying == NATIVE) {
                uint256 errCode = IQiAvax(qiToken).redeem(amountSharesToRedeem);
                require(errCode == 0, "redeem failed");
            } else {
                uint256 errCode = IQiErc20(qiToken).redeem(amountSharesToRedeem);
                require(errCode == 0, "redeem failed");
            }

            amountBaseOut = _selfBalance(underlying);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() public override returns (uint256 currentRate) {
        currentRate = IQiToken(qiToken).exchangeRateCurrent();

        emit ExchangeRateUpdated(exchangeRateStored, currentRate);

        exchangeRateStored = currentRate;
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function _getRewardTokens() internal view override returns (address[] memory res) {
        res = new address[](2);
        res[0] = QI;
        res[1] = WAVAX;
    }

    function _redeemExternalReward() internal override {
        address[] memory holders = new address[](1);
        address[] memory qiTokens = new address[](1);
        holders[0] = address(this);
        qiTokens[0] = qiToken;

        IBenQiComptroller(comptroller).claimReward(0, holders, qiTokens, false, true);
        IBenQiComptroller(comptroller).claimReward(1, holders, qiTokens, false, true);

        if (address(this).balance != 0) IWETH(WAVAX).deposit{ value: address(this).balance };
    }

    /*///////////////////////////////////////////////////////////////
                    MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseTokens() public view override returns (address[] memory res) {
        res = new address[](2);
        res[0] = qiToken;
        res[1] = underlying;
    }

    function isValidBaseToken(address token) public view override returns (bool res) {
        res = (token == underlying || token == qiToken);
    }

    function assetInfo()
        external
        view
        returns (
            AssetType assetType,
            address assetAddress,
            uint8 assetDecimals
        )
    {
        return (
            AssetType.TOKEN,
            underlying,
            underlying == NATIVE ? 18 : IERC20Metadata(underlying).decimals()
        );
    }
}
