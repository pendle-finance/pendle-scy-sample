# Super Composable Yield Overview

### Overview

- We are proposing Super Composable Yield, a new **token standard** to **standardise the interaction** with **all yield generating mechanisms in DeFi**
- We would like to ask for your technical feedback in how the standard should work, as well as general feedback in how you think it could be useful

### Let’s break it down

- What do we mean by **all yield generating mechanisms in DeFi**?
    - Money market supply positions
        - Lending DAI in Compound, getting DAI interests & COMP rewards
        - Lending ETH in BenQi, getting ETH interests & QI + AVAX rewards
        - Lending USDC in Aave, getting USDC intererests & StkAAVE rewards
        - Lending UST in Anchor, getting UST interests
    - AMM liquidity provision
        - Provide ETH + USDC to ETHUSDC pool in Sushiswap, getting swap fees in more ETH+USDC
        - Provide ETH + USDC to ETHUSDC pool in Sushiswap and stake it in Onsen, getting swap fees & SUSHI rewards
        - Provide USDC+DAI+USDT to 3crv pool and stake it in Convex, getting 3crv swap fees & CRV + CVX rewards
    - Vault positions
        - Provide ETH into Yearn, getting ETH yield from Yearn’s ETH strategy
        - Provide DAI into Harvest and staking it, getting DAI interersts & FARM rewards
    - Liquidity mining programs
        - Provide USDC in Stargate, getting STG rewards
        - Provide FEI in Tokemak, getting TOKE rewards
        - Provide LOOKS in Looksrare, getting LOOKS yield & WETH rewards
    - Rebasing tokens
        - Stake OHM into sOHM/gOHM, getting OHM rebase yield
        - Stake BTRFLY into xBTRFLY, getting BTRFLY rebase yield
- How do we **standardise the interaction** with all these yield generating mechanisms?
    - This is done by having a standard interface for all these yield generating mechanisms, in the form of a token standard (Super Composable Yield) to represent the positions in these yield generating mechanisms
    - Existing yield generating mechanisms can be **easily** **converted** into Super Composable Yield tokens through a wrapper contract.
- So, what’s the Super Composable Yield **token standard**?
    - These are the tentative functions on top of ERC20s in Super Composable Yield standard:

    ```solidity
    interface ISuperComposableYield is IERC20Metadata {
        event NewExchangeRate(uint256 exchangeRate);
        event Deposit(
            address indexed caller,
            address indexed receiver,
            address indexed tokenIn,
            uint256 amountDeposited,
            uint256 amountScyOut
        );

        event Redeem(
            address indexed caller,
            address indexed receiver,
            address indexed tokenOut,
            uint256 amountScyToRedeem,
            uint256 amountTokenOut
        );

        event ClaimRewardss(address indexed user, address[] rewardTokens, uint256[] rewardAmounts);

        function deposit(
            address receiver,
            address tokenIn,
            uint256 amountTokenToPull,
            uint256 minSharesOut
        ) external returns (uint256 amountSharesOut);

        function redeem(
            address receiver,
            uint256 amountSharesToPull,
            address tokenOut,
            uint256 minTokenOut
        ) external returns (uint256 amountTokenOut);

        /**
        * @notice exchangeRateCurrent * scyBalance / 1e18 must return the asset balance of the account
        * @notice vice-versa, if a user uses some amount of tokens equivalent to X asset, the amount of scy
        he can mint must be X * exchangeRateCurrent / 1e18
        * @dev SCYUtils's assetToScy & scyToAsset should be used instead of raw multiplication
        & division
        */
        function exchangeRateCurrent() external returns (uint256 res);

        function exchangeRateStored() external view returns (uint256 res);

        function claimRewards(address user) external returns (uint256[] memory rewardAmounts);

        function getRewardTokens() external view returns (address[] memory);

        function yieldToken() external view returns (address);

        function getBaseTokens() external view returns (address[] memory res);

        function isValidBaseToken(address token) external view returns (bool);

        /**
        * @notice This function contains information to interpret what the asset is
        * @notice decimals is the decimals to format asset balances
        * @notice if asset is an ERC20 token, assetType = 0, info is the asset token address
        * @notice if asset is liquidity of an AMM (like sqrt(k) in UniswapV2 forks), assetType = 1, 
        info is address of the AMM pool
        */
        function assetInfo() external view returns (uint8 assetType, uint8 decimals, address info);
    }
    ```

### Additional Info

More information can be found on this Notion doc.
https://www.notion.so/pendle/Super-Composable-Yield-How-it-works-00e7d9f8e6de41af8108490c458101c2
