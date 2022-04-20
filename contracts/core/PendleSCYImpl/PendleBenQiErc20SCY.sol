// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
pragma abicoder v2;
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

    uint256 public lastScyIndex;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __scydecimals,
        uint8 __assetDecimals,
        address _underlying,
        address _qiToken,
        address _comptroller,
        address _QI,
        address _WAVAX
    ) SCYBaseWithRewards(_name, _symbol, __scydecimals, __assetDecimals) {
        underlying = _underlying;
        qiToken = _qiToken;
        QI = _QI;
        WAVAX = _WAVAX;
        comptroller = _comptroller;
        IERC20(underlying).safeIncreaseAllowance(qiToken, type(uint256).max);
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address token, uint256 amountBase)
        internal
        virtual
        override
        returns (uint256 amountScyOut)
    {
        // qiToken -> scy is 1:1
        if (token == qiToken) {
            amountScyOut = amountBase;
        } else {
            IQiErc20(qiToken).mint(amountBase);
            _afterSendToken(underlying);
            amountScyOut = _afterReceiveToken(qiToken);
        }
    }

    function _redeem(address token, uint256 amountScy)
        internal
        virtual
        override
        returns (uint256 amountBaseOut)
    {
        if (token == qiToken) {
            amountBaseOut = amountScy;
        } else {
            // must be underlying
            IQiErc20(qiToken).redeem(amountScy);
            _afterSendToken(qiToken);
            amountBaseOut = _afterReceiveToken(underlying);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    function scyIndexCurrent() public virtual override returns (uint256) {
        lastScyIndex = IQiToken(qiToken).exchangeRateCurrent();
        return lastScyIndex;
    }

    function scyIndexStored() public view override returns (uint256) {
        return lastScyIndex;
    }

    function getRewardTokens() public view override returns (address[] memory res) {
        res = new address[](2);
        res[0] = QI;
        res[1] = WAVAX;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseTokens() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = qiToken;
        res[1] = underlying;
    }

    function isValidBaseToken(address token) public view virtual override returns (bool res) {
        res = (token == underlying || token == qiToken);
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
