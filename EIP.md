# Super Composable Yield Standard

---
eip: <to be assigned>
title: Super Composable Yield Token Standard
description: A standard for yield-generating tokens.
duthor: Long Vuong (@UncleGrandpa925), Vu Nguyen (@mrenoon), Anton Buenavista (@ayobuenavista)
discussions-To:	https://ethereum-magicians.org/t/
status: Draft
type: Standards Track
category: ERC
created: 2022-05-04
requires: 20
---

## Abstract

This standard outlines the implementation of a standardized smart contract interface for yield-generating tokens within smart contracts. This standard is an extension on the ERC-20 token that provides basic functionality for transferring, depositing, withdrawing tokens, and reading balances.

## Motivation

With the variety of DeFi protocols exiting today, the core utility that they provide largely remains the same: users generate yield by staking or providing liquidity to the protocol. Despite this, most protocols build their yield generating mechanisms differently, necessitating a manual integration every time a protocol builds on top of another protocol’s yield generating mechanism. In light of this problem, we introduce a standard to wrap all yield-generating tokens to standardize the interaction with all yield generating mechanisms in DeFi. This model will enable unprecedented levels of composability. Therefore, we are proposing the Super Composable Yield (SCY) token standard.

## Specification

We will first introduce the concept of a Generic Yield Generating Pool (GYGP), a model to describe most yield generating mechanisms in DeFi. Super Composable Yield (SCY) is a token standard for any yield generating mechanisms that conform to the GYGP model. Any yield-generating token (represening a share in the GYGP) can be wrapped into SCY in order for the token to conform to the SCY token standard. Any GYGP can natively implement the SCY interface to represent a share in the GYGP.

All SCY tokens:

- **MUST** implement **`ERC20`** to represent shares in the underlying GYGP.
- **MUST** implement ERC-20’s optional metadata extensions `name`, `symbol`, and `decimals`, which **SHOULD** reflect the underlying GYGP’s accounting asset’s `name`, `symbol`, and `decimals`.
- **MAY** revert on calls to `transfer` and `transferFrom` if a SCY token is to be non-transferable.
- The ERC-20 operations `balanceOf`, `transfer`, `totalSupply`, etc. **SHOULD** operate on the GYGP “shares”, which represent a claim to ownership on a fraction of the GYGP’s underlying holdings.
- **MAY** implement **`ERC2612`** to improve the UX of approving SCY tokens to various integrations.

### Definitions:

- **base tokens**: Tokens that can be converted into accounting assets to enter the pool. When exiting the pool, accounting asset can be converted back into base tokens again. Each SCY could accept several possible base tokens.
- **pool**: In each yield generating mechanism, there is a central pool that contains value contributed by users.
- **accounting asset**: Is a unit to measure the value of the pool. At time *t*, the pool has a total value of *A(t)* accounting assets shares is a unit that represents ownership of the pool. At time *t*, there are *S(t)* shares in total.
- **reward tokens**: Over time, the pool earns $n_{rewards}$ types of reward tokens $(n_{rewards} \ge 0)$. At time *t*, $R_i(t)$ is the amount of reward token *i* that has accumulated for the pool since *t = 0.*
- **exchangeRate**: At time *t*, the exchange rate *E(t)* is simply how many accounting assets each
shares is worth $E(t) = \frac{A(t)}{S(t)}$.
- **users**: At time *t*, each user *u* has $s_u(t)$ shares in the pool, which is worth $a_u(t) = s_u(t) \cdot E(t)$ accounting assets. Until time *t*, user *u* is entitled to receive a total of $r_{u_i}(t)$ reward token *i*.

### Example GYGPs:

| Yield generating mechanism | USDC lending in Compound          | Stake LOOKS in Looksrare     | Stake 3crv in Convex       |
| -------------------------- | --------------------------------- | ---------------------------- | -------------------------- |
| Accounting asset           | USDC                              | LOOKS                        | 3crv pool’s liquidity D    |
| Shares                     | cUSDC                             | shares (in contract)         | 3crv LP token              |
| Reward Tokens              | COMP                              | WETH                         | CRV + CVX                  |
| Exchange Rate              | Increases with USDC lending yield | Increases with LOOKS rewards | Increases due to swap fees |

### Interface

```solidity
interface IERCXXX is IERC20 {
    function deposit(
        address receiver,
        address baseTokenIn,
        uint256 amountBaseIn,
        uint256 minAmountScyOut
    ) external returns (uint256 amountScyOut);

    function redeem(
        address receiver,
        address baseTokenOut,
        uint256 amountScyIn,
        uint256 minAmountBaseOut
    ) external returns (uint256 amountBaseOut);

    function harvest(address user) external returns (uint256[] memory rewardAmounts);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

		function underlyingYieldToken() external view returns (address);

    function getBaseTokens() external view returns (address[] memory);

    function isValidBaseToken(address token) external view returns (bool);

    function getRewardTokens() external view returns (address[] memory);

    function assetDecimals() external view returns (uint8);

		event Deposit(address indexed caller, address indexed receiver, address indexed baseTokenIn, uint256 amountBaseIn, uint256 amountScyOut);

		event Redeem(address indexed caller, address indexed receiver, address indexed baseTokenOut, uint256 amountScyIn, uint256 amountBaseOut);

		event Harvest(address indexed caller, address indexed user, uint256[] rewardAmounts);
}
```

### Functions:

```solidity
function deposit(
    address receiver,
    address baseTokenIn,
    uint256 amountBaseIn,
    uint256 minAmountScyOut
) external returns (uint256 amountScyOut);
```

This function will convert the exact base asset into some worth of accounting assets and deposit this amount into the pool for the recipient, who will receive amountScyOut of SCY tokens (shares). Most implementations will require pre-approval of the SCY contract with SCY’s base token.

- **MUST** emit the `Deposit` event.
- **MUST** support ERC-20’s `approve` / `transferFrom` flow where *baseTokenIn* are taken from receiver directly (as msg.sender) or if the msg.sender has ERC-20 approved allowance over the base asset of the receiver.
- **MUST** revert if $amountScyOut \lt minAmountScyOut$ (due to deposit limit being reached, slippage, or the user not approving enough *baseTokenIn* to the SCY contract, etc).

```solidity
function redeem(
    address receiver,
    address baseTokenOut,
    uint256 amountScyIn,
    uint256 minAmountBaseOut
) external returns (uint256 amountBaseOut);
```

This function will redeem exact shares from the pool. The accounting assets is converted into amountBaseOut of baseTokenOut. Most implementations will require pre-approval of the SCY contract with the SCY token.

- **MUST** emit the `Redeem` event.
- **MUST** support ERC-20’s `approve` / `transferFrom` flow where the shares are burned from receiver directly (as msg.sender) or if the msg.sender has ERC-20 approved allowance over the shares of the receiver.
- **MUST** revert if $amountScyOut \lt minAmountBaseOut$ (due to redeem limit being reached, slippage, or the user not approving enough *amountScyIn* to the SCY contract, etc).

```solidity
function harvest(address user) external returns (uint256[] memory rewardAmounts);
```

This function sends the harvested rewards for the user.

- **MUST** emit the `Harvest` event.
- **MAY** return one or multiple rewards to the user.
- **MAY** return zero rewards to the user.

```solidity
function exchangeRateCurrent() external returns (uint256);
```

This function updates and returns the latest exchange rate, which is the exchange rate from 1 SCY token into accounting asset.

- **MUST** result to the asset balance of the user for $exchangeRateCurrent \cdot scyBalance$.
- **MUST NOT** include fees that are charged against the underlying yield token in the SCY contract.
- **MUST NOT** revert.
- **SHOULD** use SCYUtil.sol’s `assetToScy` and `scyToAssset` instead of raw multiplication or division.

```solidity
function exchangeRateStored() external view returns (uint256);
```

This read-only function returns the last saved value of the exchange rate.

- **MUST** result to the asset balance of the user for $exchangeRateStored \cdot scyBalance$.
- **MUST NOT** include fees that are charged against the underlying yield token in the SCY contract.
- **MUST NOT** revert.

```solidity
function underlyingYieldToken() external view returns (address);
```

This read-only function returns the underlying yield-generating token (representing a GYGP) that was wrapped into a SCY token.

- **MUST** return an ERC-20 token address.
- **MUST NOT** revert.
- **MUST** reflect the exact underlying yield-generating token address if the SCY token is a wrapped token.
- **MAY** return 0x or zero address if the SCY token is natively implemented, and not from wrapping.

```solidity
function getBaseTokens() external view returns (address[] memory);
```

This read-only function returns the list of all base tokens that can be used to Deposit into the SCY contract.

- **MUST** return ERC-20 token addresses.
- **MUST NOT** revert.
- **MAY** return one or several token addresses.

```solidity
function isValidBaseToken(address token) external view returns (bool);
```

This read-only function checks whether a token address entered is an base accepted token that can be used to mint SCY.

- **MUST NOT** revert.

```solidity
function getRewardTokens() external view returns (address[] memory);
```

This read-only function returns a list of all reward tokens.

- **MUST** return ERC-20 token addresses.
- **MUST NOT** revert.
- **MAY** return an empty list, one, or several token addresses.

```solidity
function assetDecimals() external view returns (uint8);
```

This read-only function returns the decimals of the accounting asset.

- **MUST** reflect the underlying asset’s decimals if at all possible in order to eliminate any possible source of confusion or be deemed malicious.
- **MUST NOT** revert.

```solidity
function assetId() external view returns (bytes32);
```

This read-only function returns a string to identify the accounting asset being used in the SCY token.

- **MUST NOT** revert.
- **MAY** simply be the token address converted to bytes32, if the accounting asset is a simple token asset. (e.g. for SCY-cDAI, the `assetId` is the DAI address)
- **MAY** be the bytes32 equivalent of `"liquidity: address of the AMM pool"`. (e.g. or SCY-Sushiswap-ETHUSDC, the `assetId` is `bytes32(liquidity: <address of ETHUSDC pool>)`

### Events:

```solidity
event Deposit(address indexed caller, address indexed receiver, address indexed baseTokenIn, uint256 amountBaseIn, uint256 amountScyOut);
```

`caller` has converted exact base assets into SCY (shares), and transferred those SCY to `receiver`.

- **MUST** be emitted when base assets are deposited into the SCY contract via `deposit` function.

```solidity
event Redeem(address indexed caller, address indexed receiver, address indexed baseTokenOut, uint256 amountScyIn, uint256 amountBaseOut);
```

`caller` has converted exact SCY (shares) into base assets, and transferred those base assets to `receiver`.

- **MUST** be emitted when base assets are redeemed from the SCY contract via `redeem` function.

```solidity
event Harvest(address indexed caller, address indexed user, uint256[] rewardAmounts);
```

`caller` harvested user rewards and transferred them to the user.

- **MUST** be emitted when rewards are harvested from the SCY contract via `harvest` function.

**"SCY" Word Choice:**

"SCY" (pronunciation: */sʌɪ/*) was acceptable and widely usable to describe a broad universe of composable yield-bearing digital assets.

## Rationale

This EIP targets the Cambrian explosion of yield generating avenues, however each one implementing their own standards and interfaces. Particular, this standard aims to be generalized enough that it supports the following uses cases and more:

- Money market supply positions
    - Lending DAI in Compound, getting DAI interests and COMP rewards
    - Lending ETH in BenQi, getting ETH interests and QI + AVAX rewards
    - Lending USDC in Aave, getting USDC interests and StkAAVE rewards
    - Lending UST in Anchor, getting UST interests
- AMM liquidity provision
    - Provide ETH + USDC to ETHUSDC pool in SushiSwap, getting swap fees in more ETH+USDC
    - Provide ETH + USDC to ETHUSDC pool in SushiSwap and stake it in Sushi Onsen, getting swap fees and SUSHI rewards
    - Provide USDC+DAI+USDT to 3crv pool and stake it in Convex, getting 3crv swap fees and CRV + CVX rewards
- Vault positions
    - Provide ETH into Yearn ERC-4626 vault, where the vault accrues yield from Yearn’s ETH strategy
    - Provide DAI into Harvest and staking it, getting DAI interests and FARM rewards
- Liquidity mining programs
    - Provide USDC in Stargate, getting STG rewards
    - Provide FEI in Tokemak, getting TOKE rewards
    - Provide LOOKS in Looksrare, getting LOOKS yield and WETH rewards
- Rebasing tokens
    - Stake OHM into sOHM/gOHM, getting OHM rebase yield
    - Stake BTRFLY into xBTRFLY, getting BTRFLY rebase yield

In summary, this EIP aims to support multiple yield-generating token classes and accounts for yield-generating tokens that return multiple rewards. The EIP hopes to minimize, if not possibly eliminate, the use of customized adapters in order to interact with many different forms of yield-generating token mechanisms.

ERC-20 is enforced because implementation details such as transfer, token approvals, and balance calculation directly carry over to the SCY tokens. This standardization makes the SCY tokens immediately compatible with all ERC-20 use cases.

## Backwards Compatibility

This EIP is fully backwards compatible as its implementation extends the functionality of [ERC-20](https://eips.ethereum.org/EIPS/eip-20), however the optional metadata extensions, namely `name`, `decimals`, and `symbol` semantics MUST be implemented for all SCY token implementations.

## Reference Implementations

See [PendleAaveV3SCY](https://github.com/pendle-finance/pendle-scy-sample/tree/main/contracts/SuperComposableYield/PendleSCYImpl/AaveV3): an opinionated implementation of the SCY token standard for AaveV3 tokens.

See [PendleBenQiSCY](https://github.com/pendle-finance/pendle-scy-sample/blob/main/contracts/SuperComposableYield/PendleSCYImpl/PendleBenQiErc20SCY.sol): an opinionated implementation of the SCY token standard for BenQi tokens.

See [PendleBtrflySCY](https://github.com/pendle-finance/pendle-scy-sample/blob/main/contracts/SuperComposableYield/PendleSCYImpl/PendleBtrflySCY.sol): an opinionated implementation of the SCY token standard for [Redacted Cartel]’s BTRFLY token.

See [PendleStETHSCY](https://github.com/pendle-finance/pendle-scy-sample/blob/main/contracts/SuperComposableYield/PendleSCYImpl/PendleStETHSCY.sol): an opinionated implementation of the SCY token standard for stETH token.

See [PendleYearnVaultSCY](https://github.com/pendle-finance/pendle-scy-sample/blob/main/contracts/SuperComposableYield/PendleSCYImpl/PendleYearnVaultSCY.sol): an opinionated implementation of the SCY token standard for Yearn Vault tokens.

## Security Considerations

Malicious implementations which conform to the interface can put users at risk. It is recommended that all integrators to review the implementation as to avoid possible exploits and users losing funds.

The function `exchangeRateStored` returns an estimate useful for display purposes off-chain, and do not confer to the exact exchange rate of price share. Should accuracy be needed, `exchangeRateCurrent` should be used instead, and in addition, will update `exchangeRateStored`.

`assetDecimals` must strongly reflect the underlying asset’s decimals if at all possible in order to eliminate any possible source of confusion or be deemed malicious.

`underlyingYieldToken` must strongly reflect the address of the underlying wrapped yield-generating token. For a native implementation wherein the SCY token does not wrap a a yield-generating token, but natively represents a GYGP share, then the address returned MAY be a zero address. Otherwise, for wrapped tokens, you may introduce confusions on what the SCY token represents, or may be deemed malicious.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).