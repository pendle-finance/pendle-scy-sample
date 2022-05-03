// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../SuperComposableYield/implementations/SCYBase.sol";
import "../../interfaces/IWXBTRFLY.sol";
import "../../interfaces/IREDACTEDStaking.sol";

contract PendleBtrflyScy is SCYBase {
    using SafeERC20 for IERC20;

    address public immutable BTRFLY;
    address public immutable xBTRFLY;
    address public immutable wxBTRFLY;

    uint256 public override exchangeRateStored;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __scydecimals,
        uint8 __assetDecimals,
        bytes32 __assetId,
        address _BTRFLY,
        address _xBTRFLY,
        address _wxBTRFLY
    ) SCYBase(_name, _symbol, __scydecimals, __assetDecimals, __assetId) {
        require(_wxBTRFLY != address(0), "zero address");
        BTRFLY = _BTRFLY;
        xBTRFLY = _xBTRFLY;
        wxBTRFLY = _wxBTRFLY;
        IERC20(BTRFLY).safeIncreaseAllowance(wxBTRFLY, type(uint256).max);
        IERC20(xBTRFLY).safeIncreaseAllowance(wxBTRFLY, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/
    function _deposit(address token, uint256 amountBase)
        internal
        virtual
        override
        returns (uint256 amountScyOut)
    {
        if (token == wxBTRFLY) {
            amountScyOut = amountBase;
        } else if (token == xBTRFLY) {
            // wrapFromxBTRFLY returns amountWXBTRFLYout
            amountScyOut = IWXBTRFLY(wxBTRFLY).wrapFromxBTRFLY(amountBase);
        } else {
            // must be BTRFLY
            // wrapFromBTRFLY returns amountWXBTRFLYout
            amountScyOut = IWXBTRFLY(wxBTRFLY).wrapFromBTRFLY(amountBase);
        }
    }

    function _redeem(address token, uint256 amountScy)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (token == wxBTRFLY) {
            amountTokenOut = amountScy;
        } else if (token == xBTRFLY) {
            amountTokenOut = IWXBTRFLY(wxBTRFLY).unwrapToxBTRFLY(amountScy);
        } else {
            // must be BTRFLY
            amountTokenOut = IWXBTRFLY(wxBTRFLY).unwrapToBTRFLY(amountScy);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() public virtual override returns (uint256) {
        uint256 res = IWXBTRFLY(wxBTRFLY).xBTRFLYValue(Math.ONE);

        exchangeRateStored = res;
        emit UpdateExchangeRate(res);

        return res;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseTokens() public view virtual override returns (address[] memory res) {
        res = new address[](3);
        res[0] = BTRFLY;
        res[1] = xBTRFLY;
        res[2] = wxBTRFLY;
    }

    function isValidBaseToken(address token) public view virtual override returns (bool) {
        return token == BTRFLY || token == xBTRFLY || token == wxBTRFLY;
    }

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    //solhint-disable-next-line no-empty-blocks
    function redeemReward(address user) public virtual override returns (uint256[] memory) {}

    function getRewardTokens() public view virtual returns (address[] memory res) {
        res = new address[](0);
    }

    //solhint-disable-next-line no-empty-blocks
    function _redeemExternalReward() internal virtual {}
}
