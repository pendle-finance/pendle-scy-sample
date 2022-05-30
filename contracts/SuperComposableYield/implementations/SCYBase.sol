// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../ISuperComposableYield.sol";
import "./RewardManager.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../libraries/math/Math.sol";
import "./SCYUtils.sol";
import "./TokenHelper.sol";

abstract contract SCYBase is ISuperComposableYield, ERC20, ReentrancyGuard, TokenHelper {
    using Math for uint256;

    uint8 private immutable _sharesDecimals;

    uint8 public immutable assetDecimals;
    bytes32 public immutable assetId;

    address public immutable yieldToken;

    uint256 public yieldTokenReserve;

    modifier updateReserve() {
        _;
        _updateReserve();
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _yieldToken,
        uint8 __sharesDecimals,
        uint8 __assetDecimals,
        bytes32 __assetId
    ) ERC20(_name, _symbol) {
        yieldToken = _yieldToken;
        _sharesDecimals = __sharesDecimals;
        assetDecimals = __assetDecimals;
        assetId = __assetId;
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToPull,
        uint256 minSharesOut
    ) external payable nonReentrant updateReserve returns (uint256 amountSharesOut) {
        require(isValidBaseToken(tokenIn), "SCY: Invalid tokenIn");

        if (tokenIn == NATIVE) require(amountTokenToPull == 0, "can't pull eth");
        else if (amountTokenToPull != 0) _transferIn(tokenIn, msg.sender, amountTokenToPull);

        uint256 amountDeposited = _getFloatingAmount(tokenIn);

        amountSharesOut = _deposit(tokenIn, amountDeposited);
        require(amountSharesOut >= minSharesOut, "insufficient out");

        _mint(receiver, amountSharesOut);
        emit Deposit(msg.sender, receiver, tokenIn, amountDeposited, amountSharesOut);
    }

    function redeem(
        address receiver,
        uint256 amountSharesToPull,
        address tokenOut,
        uint256 minTokenOut
    ) external nonReentrant updateReserve returns (uint256 amountTokenOut) {
        require(isValidBaseToken(tokenOut), "SCY: invalid tokenOut");

        if (amountSharesToPull != 0) transferFrom(msg.sender, address(this), amountSharesToPull);

        uint256 amountSharesToRedeem = _getFloatingAmount(address(this));

        amountTokenOut = _redeem(tokenOut, amountSharesToRedeem);
        require(amountTokenOut >= minTokenOut, "insufficient out");

        _burn(address(this), amountSharesToRedeem);
        _transferOut(tokenOut, receiver, amountTokenOut);

        emit Redeem(msg.sender, receiver, tokenOut, amountSharesToRedeem, amountTokenOut);
    }

    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        returns (uint256 amountSharesOut);

    function _redeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        virtual
        returns (uint256 amountTokenOut);

    function _updateReserve() internal virtual {
        yieldTokenReserve = _selfBalance(yieldToken);
    }

    function _getFloatingAmount(address token) internal view virtual returns (uint256) {
        if (token != yieldToken) return _selfBalance(token);
        return _selfBalance(token) - yieldTokenReserve;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() external virtual override returns (uint256);

    function exchangeRateStored() external view virtual override returns (uint256);

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function claimRewards(
        address /*user*/
    ) external virtual override returns (uint256[] memory rewardAmounts) {
        rewardAmounts = new uint256[](0);
    }

    function getRewardTokens()
        external
        view
        virtual
        override
        returns (address[] memory rewardTokens)
    {
        rewardTokens = new address[](0);
    }

    function accruedRewards(
        address /*user*/
    ) external view virtual override returns (uint256[] memory rewardAmounts) {
        rewardAmounts = new uint256[](0);
    }

    /*///////////////////////////////////////////////////////////////
                MISC METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return _sharesDecimals;
    }

    function getBaseTokens() external view virtual override returns (address[] memory res);

    function isValidBaseToken(address token) public view virtual override returns (bool);
}
