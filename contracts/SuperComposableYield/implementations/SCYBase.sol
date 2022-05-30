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

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ISuperComposableYield-deposit} 
     */
    function deposit(
        address receiver,
        address tokenIn,
        uint256 amountTokenToPull,
        uint256 minSharesOut
    ) external nonReentrant updateReserve returns (uint256 amountSharesOut) {
        require(isValidBaseToken(tokenIn), "SCY: Invalid tokenIn");

        if (amountTokenToPull != 0)
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountTokenToPull);

        uint256 amountDeposited = _getFloatingAmount(tokenIn);

        amountSharesOut = _deposit(tokenIn, amountDeposited);
        require(amountSharesOut >= minSharesOut, "insufficient out");

        _mint(receiver, amountSharesOut);
        emit Deposit(msg.sender, receiver, tokenIn, amountDeposited, amountSharesOut);
    }

    /**
     * @dev See {ISuperComposableYield-redeem} 
     */
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

    /**
     * @notice mint shares based on the deposited base tokens
     * @param tokenIn base token address used to mint shares
     * @param amountDeposited amount of base tokens deposited
     * @return amountSharesOut amount of shares minted
     */
    function _deposit(address tokenIn, uint256 amountDeposited)
        internal
        virtual
        returns (uint256 amountSharesOut);

    /**
     * @notice redeems base tokens based on amount of shares to be burned
     * @param tokenOut address of the base token to be redeemed
     * @param amountSharesToRedeem amount of shares to be burned
     * @return amountTokenOut amount of base tokens redeemed
     */
    function _redeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        virtual
        returns (uint256 amountTokenOut);

    /**
     * @notice updates the amount of yield token reserves in this contract
     */
    function _updateReserve() internal virtual {
        yieldTokenReserve = IERC20(yieldToken).balanceOf(address(this));
    }

    /**
     * @notice returns the amount of unprocessed tokens owned by this contract
     * @param token address of the token to be queried
     */
    function _getFloatingAmount(address token) internal view virtual returns (uint256) {
        if (token != yieldToken) return IERC20(token).balanceOf(address(this));
        return IERC20(token).balanceOf(address(this)) - yieldTokenReserve;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ISuperComposableYield-exchangeRateCurrent} 
     */
    function exchangeRateCurrent() external virtual override returns (uint256 res);

    /**
     * @dev See {ISuperComposableYield-exchangeRateStored} 
     */
    function exchangeRateStored() external view virtual override returns (uint256 res);

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {ISuperComposableYield-claimRewards}
     */
    function claimRewards(address user)
        external
        virtual
        override
        returns (uint256[] memory rewardAmounts);

    /**
     * @dev See {ISuperComposableYield-getRewardTokens}
     */
    function getRewardTokens() external view virtual override returns (address[] memory);

    /*///////////////////////////////////////////////////////////////
                MISC METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice See {ISuperComposableYield-decimals}
     */
    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return _sharesDecimals;
    }

    /**
     * @notice See {ISuperComposableYield-getBaseTokens}
     */
    function getBaseTokens() external view virtual override returns (address[] memory res);

    /**
     * @dev See {ISuperComposableYield-isValidBaseToken}
     */
    function isValidBaseToken(address token) public view virtual override returns (bool);
}
