// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import "../ISuperComposableYield.sol";
import "./RewardManager.sol";
import "./SCYBase.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../libraries/math/Math.sol";

abstract contract SCYBaseWithRewards is SCYBase, RewardManager {
    using Math for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        address _yieldToken
    )
        SCYBase(_name, _symbol, yieldToken) // solhint-disable-next-line no-empty-blocks
    {}

    /*///////////////////////////////////////////////////////////////
                               REWARDS-RELATED
    //////////////////////////////////////////////////////////////*/

    function claimRewards(address user)
        external
        virtual
        override
        returns (uint256[] memory rewardAmounts)
    {
        _updateAndDistributeReward(user);
        rewardAmounts = _doTransferOutRewards(user, user);

        emit ClaimRewards(user, _getRewardTokens(), rewardAmounts);
    }

    function getRewardTokens()
        external
        view
        virtual
        override
        returns (address[] memory rewardTokens)
    {
        rewardTokens = _getRewardTokens();
    }

    function accruedRewards(address user)
        external
        view
        virtual
        override
        returns (uint256[] memory rewardAmounts)
    {
        address[] memory rewardTokens = _getRewardTokens();
        rewardAmounts = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; ) {
            rewardAmounts[i] = userRewardAccrued[user][rewardTokens[i]];
            unchecked {
                i++;
            }
        }
    }

    function _rewardSharesTotal() internal virtual override returns (uint256) {
        return totalSupply();
    }

    function _rewardSharesUser(address user) internal virtual override returns (uint256) {
        return balanceOf(user);
    }

    /*///////////////////////////////////////////////////////////////
                            TRANSFER HOOKS
    //////////////////////////////////////////////////////////////*/
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal virtual override {
        _updateRewardIndex();
        if (from != address(0) && from != address(this)) _distributeUserReward(from);
        if (to != address(0) && to != address(this)) _distributeUserReward(to);
    }
}
