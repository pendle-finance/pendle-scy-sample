// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../../SuperComposableYield/implementations/SCYBase.sol";
import "../../interfaces/IERC4626.sol";
import "../../libraries/math/Math.sol";

contract PendleStEthSCY is SCYBase {
    using SafeERC20 for IERC20;
    using Math for uint256;

    address public immutable underlying;
    address public immutable yieldToken;

    uint256 public override exchangeRateStored;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __scydecimals,
        uint8 __assetDecimals,
        address _underlying,
        address _yieldToken,
        bytes32 __assetId
    ) SCYBase(_name, _symbol, __scydecimals, __assetDecimals, __assetId) {
        require(_underlying != address(0), "zero address");
        require(_yieldToken != address(0), "zero address");
        underlying = _underlying;
        yieldToken = _yieldToken;
        IERC20(underlying).safeIncreaseAllowance(yieldToken, type(uint256).max);
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
        if (token == yieldToken) {
            amountScyOut = amountBase;
        } else {
            // must be underlying
            amountScyOut = IERC4626(yieldToken).deposit(amountBase, address(this)); // deposit() returns exactly this number of shares
        }
    }

    function _toBaseToken(address token, uint256 amountScy)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (token == yieldToken) {
            amountTokenOut = amountScy;
        } else {
            amountTokenOut = IERC4626(yieldToken).redeem(amountScy, address(this), msg.sender);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() public virtual override returns (uint256) {
        uint256 res = IERC4626(yieldToken).convertToAssets(1e18);

        exchangeRateStored = res;
        emit UpdateExchangeRate(res);

        return res;
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

    function underlyingYieldToken() external view virtual override returns (address) {
        return yieldToken;
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
