// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../../SuperComposableYield/implementations/SCYBase.sol";
import "../../interfaces/IWstETH.sol";

contract PendleWstEthSCY is SCYBase {
    address public immutable stETH;
    address public immutable wstETH;

    uint256 public override exchangeRateStored;

    constructor(
        string memory _name,
        string memory _symbol,
        address _stETH,
        address _wstETH
    ) SCYBase(_name, _symbol, _wstETH) {
        require(_wstETH != address(0), "zero address");
        stETH = _stETH;
        wstETH = _wstETH;
        _safeApprove(stETH, wstETH, type(uint256).max);
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
        if (tokenIn == wstETH) {
            amountSharesOut = amountDeposited;
        } else {
            amountSharesOut = IWstETH(wstETH).wrap(amountDeposited); // .wrap returns amount of wstETH out
        }
    }

    function _redeem(address tokenOut, uint256 amountSharesToRedeem)
        internal
        virtual
        override
        returns (uint256 amountTokenOut)
    {
        if (tokenOut == wstETH) {
            amountTokenOut = amountSharesToRedeem;
        } else {
            amountTokenOut = IWstETH(wstETH).unwrap(amountSharesToRedeem);
        }
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRateCurrent() public virtual override returns (uint256) {
        uint256 res = IWstETH(wstETH).stEthPerToken();

        exchangeRateStored = res;
        emit NewExchangeRate(res);

        return res;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function getBaseTokens() public view virtual override returns (address[] memory res) {
        res = new address[](2);
        res[0] = stETH;
        res[1] = wstETH;
    }

    function isValidBaseToken(address token) public view virtual override returns (bool) {
        return token == stETH || token == wstETH;
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
        return (AssetType.TOKEN, stETH, IERC20Metadata(stETH).decimals());
    }
}
