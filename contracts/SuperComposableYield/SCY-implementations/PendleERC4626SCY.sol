// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../base-implementations/SCYBase.sol";
import "../../interfaces/IERC4626.sol";
import "../../libraries/math/Math.sol";

contract PendleERC4626SCY is SCYBase {
    using Math for uint256;

    address public immutable underlying;

    uint256 public override exchangeRateStored;

    constructor(
        string memory _name,
        string memory _symbol,
        IERC4626 _yieldToken
    ) SCYBase(_name, _symbol, address(_yieldToken)) {
        underlying = _yieldToken.asset();
        _safeApprove(underlying, yieldToken, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {SCYBase-_deposit}
     *
     * If the base token deposited is the underlying token, the function deposits it first to mint
     * the corresponding ERC4626 token. Then the amount of shares is returned.
     *
     * The exchange rate of ERC4626 token to shares is 1:1
     */
    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        override
        returns (uint256 amountSharesOut)
    {
        // 1 4626 = 1 Share
        if (tokenIn == yieldToken) {
            amountSharesOut = amountDeposited;
        } else {
            // must be underlying
            amountSharesOut = IERC4626(yieldToken).deposit(amountDeposited, address(this));
        }
    }

    /**
     * @dev See {SCYBase-_redeem}
     *
     * The shares are redeemed into the same amount of ERC4626 tokens. If `tokenOut` is the underlying token,
     * the function also redeems said asset, then returns the amount of underlying tokens for redemption.
     */
    function _redeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (tokenOut == yieldToken) {
            amountTokenOut = amountSharesToRedeem;
        } else {
            amountTokenOut = IERC4626(yieldToken).redeem(
                amountSharesToRedeem,
                address(this),
                address(this)
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates and updates the exchange rate of shares to underlying asset token
     * @dev It is the conversion rate of the ERC4626 to its underlying token
     */
    function exchangeRateCurrent() public virtual override returns (uint256 currentRate) {
        currentRate = IERC4626(yieldToken).convertToAssets(Math.ONE);

        emit ExchangeRateUpdated(exchangeRateStored, currentRate);

        exchangeRateStored = currentRate;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseTokens() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = underlying;
        res[1] = yieldToken;
    }

    function isValidBaseToken(address token) public view virtual override returns (bool) {
        return token == underlying || token == yieldToken;
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
        return (AssetType.TOKEN, underlying, IERC20Metadata(underlying).decimals());
    }
}
