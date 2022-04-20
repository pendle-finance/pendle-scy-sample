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
    
    ```jsx
    function mintNoPull(
        address receiver,
        address baseTokenIn,
        uint256 minAmountScyOut
    ) external returns (uint256 amountScyOut);

    function redeemNoPull(
        address receiver,
        address baseTokenOut,
        uint256 minAmountBaseOut
    ) external returns (uint256 amountBaseOut);

    function mint(
        address receiver,
        address baseTokenIn,
        uint256 amountBaseToPull,
        uint256 minAmountScyOut
    ) external returns (uint256 amountScyOut);

    function redeem(
        address receiver,
        address baseTokenOut,
        uint256 amountScyToPull,
        uint256 minAmountBaseOut
    ) external returns (uint256 amountBaseOut);
    
    function updateGlobalRewards() external;
    function updateUserRewards(address user) external;
    function redeemReward(address user) external returns (uint256[] memory outAmounts);
    
    function scyIndexCurrent() external returns (uint256);
    function scyIndexStored() external view returns (uint256);
    
    function getBaseTokens() external view returns (address[] memory);
    function isValidBaseToken(address token) external view returns (bool);
    function getRewardTokens() external view returns (address[] memory);
    
    // Metadata
    function assetDecimals() external view returns (uint8);
    function assetId() external view returns (bytes32);
    ```

## Why not ERC4626?

ERC-4626 is a standard for vaults, which is not flexible enough to include many other yield generating mechanisms

- The inputs to mint an ERC-4626 must be the same as the units for accounting for value
    - The LP-token class cannot conform to this standard. This will effectively exclude Uniswap-fork’s LP, Balancer’s LP, Curve’s LP ....
    - Any future yield-generating protocols that allow the deposit of multiple baseTokens will also not be compatible with ERC4626
- It also means that ERC4626 cannot be used to wrap existing yield tokens. Compound’s cToken, AaveV3’s aToken is still very widely used nowadays
- The standard also doesn’t take into account reward tokens, which is also widely given together with the yield. This means for yield-trading protocols OR vault protocol, a customised adapter to account for rewards of each token will still be required
