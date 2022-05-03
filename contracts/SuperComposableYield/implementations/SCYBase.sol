// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../ISuperComposableYield.sol";
import "./RewardManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../libraries/math/Math.sol";
import "../SCYUtils.sol";

abstract contract SCYBase is ERC20, ISuperComposableYield {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint8 private immutable _scyDecimals;
    uint8 public immutable assetDecimals;
    bytes32 public immutable assetId;

    event UpdateExchangeRate(uint256 exchangeRate);
    event Deposit(
        address indexed caller,
        address indexed receiver,
        address indexed baseTokenIn,
        uint256 amountBaseIn,
        uint256 amountScyOut
    );
    event Redeem(
        address indexed caller,
        address indexed receiver,
        address indexed baseTokenOut,
        uint256 amountScyIn,
        uint256 amountBaseOut
    );
    event RedeemRewards(address indexed user, address[] rewardTokens, uint256[] rewardAmounts);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __scyDecimals,
        uint8 __assetDecimals,
        bytes32 __assetId
    ) ERC20(_name, _symbol) {
        _scyDecimals = __scyDecimals;
        assetDecimals = __assetDecimals;
        assetId = __assetId;
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function deposit(
        address receiver,
        address baseTokenIn,
        uint256 amountBaseIn,
        uint256 minAmountScyOut
    ) external returns (uint256 amountScyOut) {
        require(isValidBaseToken(baseTokenIn), "invalid base token");

        /// ------------------------------------------------------------
        /// ext-call before internal-state-changes else ERC777 can reenter
        /// ------------------------------------------------------------
        IERC20(baseTokenIn).safeTransferFrom(msg.sender, address(this), amountBaseIn);

        amountScyOut = _deposit(baseTokenIn, amountBaseIn);
        require(amountScyOut >= minAmountScyOut, "insufficient out");

        /// ------------------------------------------------------------
        /// internal-state-changes
        /// ------------------------------------------------------------
        _mint(receiver, amountScyOut);

        emit Deposit(msg.sender, receiver, baseTokenIn, amountBaseIn, amountScyOut);
    }

    function redeem(
        address receiver,
        address baseTokenOut,
        uint256 amountScyIn,
        uint256 minAmountBaseOut
    ) external returns (uint256 amountBaseOut) {
        require(isValidBaseToken(baseTokenOut), "invalid base token");

        /// ------------------------------------------------------------
        /// internal-state-changes
        /// ------------------------------------------------------------
        _burn(msg.sender, amountScyIn);

        /// ------------------------------------------------------------
        /// ext-call
        /// ------------------------------------------------------------
        amountBaseOut = _redeem(baseTokenOut, amountScyIn);
        require(amountBaseOut >= minAmountBaseOut, "insufficient out");

        IERC20(baseTokenOut).safeTransfer(receiver, amountBaseOut);

        emit Redeem(msg.sender, receiver, baseTokenOut, amountScyIn, amountBaseOut);
    }

    function _deposit(address token, uint256 amountBase)
        internal
        virtual
        returns (uint256 amountScyOut);

    function _redeem(address token, uint256 amountScy)
        internal
        virtual
        returns (uint256 amountTokenOut);

    /*///////////////////////////////////////////////////////////////
                               SCY-INDEX
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() external virtual override returns (uint256 res);

    function exchangeRateStored() external view virtual override returns (uint256 res);

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function redeemReward(address user)
        public
        virtual
        override
        returns (uint256[] memory outAmounts);

    function getRewardTokens() external view virtual override returns (address[] memory);

    /*///////////////////////////////////////////////////////////////
                MISC METADATA FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function decimals() public view virtual override(ERC20, IERC20Metadata) returns (uint8) {
        return _scyDecimals;
    }

    function getBaseTokens() external view virtual override returns (address[] memory res);

    function isValidBaseToken(address token) public view virtual override returns (bool);

    function underlyingYieldToken() external view virtual override returns (address);
}
