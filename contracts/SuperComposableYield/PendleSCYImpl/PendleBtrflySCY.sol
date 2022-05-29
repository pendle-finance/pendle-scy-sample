// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "../../SuperComposableYield/implementations/SCYBase.sol";
import "../../interfaces/IWXBTRFLY.sol";
import "../../interfaces/IREDACTEDStaking.sol";

contract PendleBtrflyScy is SCYBase {
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
    ) SCYBase(_name, _symbol, _wxBTRFLY, __scydecimals, __assetDecimals, __assetId) {
        require(_wxBTRFLY != address(0), "zero address");
        BTRFLY = _BTRFLY;
        xBTRFLY = _xBTRFLY;
        wxBTRFLY = _wxBTRFLY;
        _safeApprove(BTRFLY, wxBTRFLY, type(uint256).max);
        _safeApprove(xBTRFLY, wxBTRFLY, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 amountSharesOut)
    {
        if (tokenIn == wxBTRFLY) {
            amountSharesOut = amountDeposited;
        } else if (tokenIn == xBTRFLY) {
            // wrapFromxBTRFLY returns amountWXBTRFLYout
            amountSharesOut = IWXBTRFLY(wxBTRFLY).wrapFromxBTRFLY(amountDeposited);
        } else {
            // must be BTRFLY
            // wrapFromBTRFLY returns amountWXBTRFLYout
            amountSharesOut = IWXBTRFLY(wxBTRFLY).wrapFromBTRFLY(amountDeposited);
        }
    }

    function _redeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (tokenOut == wxBTRFLY) {
            amountTokenOut = amountSharesToRedeem;
        } else if (tokenOut == xBTRFLY) {
            amountTokenOut = IWXBTRFLY(wxBTRFLY).unwrapToxBTRFLY(amountSharesToRedeem);
        } else {
            // must be BTRFLY
            amountTokenOut = IWXBTRFLY(wxBTRFLY).unwrapToBTRFLY(amountSharesToRedeem);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() public virtual override returns (uint256) {
        uint256 res = IWXBTRFLY(wxBTRFLY).xBTRFLYValue(Math.ONE);

        exchangeRateStored = res;
        emit NewExchangeRate(res);

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
}
