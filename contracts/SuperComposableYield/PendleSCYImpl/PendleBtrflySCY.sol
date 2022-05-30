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
    ) SCYBase(_name, _symbol, _wxBTRFLY, __scydecimals, __assetDecimals, __assetId) {
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

    /**
     * @dev See {SCYBase-_deposit}
     *  
     * The underlying yield token is wxBTRFLY. If the base token is not said token, the contract
     * first wraps from `tokenIn` to wxBRTRFLY. Then the corresponding amount of shares is returned.
     *
     * The exchange rate of wxBTRFLY to shares is 1:1
     */
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

    /**
     * @dev See {SCYBase-_redeem}
     * 
     * The shares are redeemed into the same amount of wxBTRFLY. If `tokenOut` is not wxBTRFLY 
     * the function unwraps said amount of wxBTRFLY into `tokenOut` for redemption.
     */
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

    /**
     * @notice Calculates and updates the exchange rate of shares to underlying asset token
     * @dev It is the conversion rate of wxBTRFLY to BTRFLY
     */
    function exchangeRateCurrent() public virtual override returns (uint256) {
        uint256 res = IWXBTRFLY(wxBTRFLY).xBTRFLYValue(Math.ONE);

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
        res = new address[](3);
        res[0] = BTRFLY;
        res[1] = xBTRFLY;
        res[2] = wxBTRFLY;
    }

    /**
     * @dev See {ISuperComposableYield-isValidBaseToken}
     */
    function isValidBaseToken(address token) public view virtual override returns (bool) {
        return token == BTRFLY || token == xBTRFLY || token == wxBTRFLY;
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
