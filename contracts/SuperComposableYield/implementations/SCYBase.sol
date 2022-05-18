// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../ISuperComposableYield.sol";
import "./RewardManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../libraries/math/Math.sol";
import "./SCYUtils.sol";

abstract contract SCYBase is ISuperComposableYield, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint8 private immutable _sharesDecimals;
    uint8 public immutable assetDecimals;
    bytes32 public immutable assetId;

    mapping(address => uint256) public reserve;

    modifier updateReserve() {
        _;
        address[] memory tokens = getReserveTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            reserve[tokens[i]] = IERC20(tokens[i]).balanceOf(address(this));
        }
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __sharesDecimals,
        uint8 __assetDecimals,
        bytes32 __assetId
    ) ERC20(_name, _symbol) {
        _sharesDecimals = __sharesDecimals;
        assetDecimals = __assetDecimals;
        assetId = __assetId;
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToPull,
        uint256 minSharesOut
    ) external nonReentrant updateReserve returns (uint256 amountSharesOut) {
        require(isValidBaseToken(tokenIn), "SCY: Invalid tokenIn");

        if (amountTokenToPull != 0)
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountTokenToPull);

        uint256 amountDeposited = getFloatingAmount(tokenIn);

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

        uint256 amountSharesToRedeem = balanceOf(address(this));

        amountTokenOut = _redeem(tokenOut, amountSharesToRedeem);
        require(amountTokenOut >= minTokenOut, "insufficient out");

        IERC20(tokenOut).safeTransfer(receiver, amountTokenOut);
        _burn(address(this), amountSharesToRedeem);

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

    function getFloatingAmount(address token) public view virtual override returns (uint256) {
        if (_isValidReserveToken(token))
            return IERC20(token).balanceOf(address(this)) - reserve[token];
        else return IERC20(token).balanceOf(address(this));
    }

    function _isValidReserveToken(address token) internal view virtual returns (bool);

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() external virtual override returns (uint256 res);

    function exchangeRateStored() external view virtual override returns (uint256 res);

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function harvest(address user)
        public
        virtual
        override
        returns (uint256[] memory rewardAmounts);

    function getRewardTokens() external view virtual override returns (address[] memory);

    /*///////////////////////////////////////////////////////////////
                MISC METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return _sharesDecimals;
    }

    function getBaseTokens() external view virtual override returns (address[] memory res);

    function getReserveTokens() public view virtual override returns (address[] memory res);

    function isValidBaseToken(address token) public view virtual override returns (bool);

    function underlyingYieldToken() external view virtual override returns (address);
}
