# Safe Accounts Assignment
## Point-in-time analysis of Safe Accounts via the Dune Analytics Youtube training. 

📊 This dashboard was created by me following Dune's Youtube series using Safe Wallets as a case study to demonstrate how to conduct point-in-time analysis for a topic.

🟠 Scope: only looking at Safes created in the past 6 months on Ethereum mainnet and only considering ETH and ERC20 tokens and not ERC721 or ERC1155.

### Concepts and Metrics 

Point Analysis: analysis done for one point in time, as opposed to trend analysis done over a period of time. E.g. for Feb 12 as opposed to for the period of Jan 1 to Feb 12.

Volume or Liquidity: used interchangeably here, defined as the inflow plus outflow liquidity to the account. More specifically, this looks at the absolute USD value of the total transfer in and transfer out amount for ETH and all ERC20 tokens (that are available in Dune's prices.usd table)

## Queries

### Decentralization
- Safes are multi-signature wallets/accounts that enable you to have multiple owners or signers. You can set a threshold of the signers before you can execute any transactions. So with this category of metrics we want to look at
- how many signers in the Safe
- threshold ratio (num signers required to act / total num signers)

### Usage and Activeness
We want to look at how the Safe is used and how active a particular Safe is, such as
- average monthly number of txns in the past (finished) 3 months
- total monthly number of txns in the past (finished) 3 months
- average monthly USD volume in the past (finished) 3 months
- total monthly USD volume in the past (finished) 3 months
- percent volume in stablecoins (for how stablecoins are defined please refer to this query)
  
### TVL and Diversification 
This metric category looks at the total value locked in USD terms (or wealth or balance in more traditional terms) as well as how diversified this Safe is if we were to treat it as a portfolio in the traditional sense. Things we look at include:
- TVL (USD)-
- Stablecoin vs. Non-Stablecoins’s TVL
- Percent TVL in Stablecoins
- Number of different Assets in the Safe
- HHI: using Herfindahl-Hirschman Index as a measure to help us understand how diversified a "market" aka a Safe is. The higher the HHI the less diversified.
- Weighted Average Volatility of Assets: we want to measure the volatility of the assets in the Safe. To do that, ideally, we would do portfolio variance. But given that covariance is not something we can achieve with SQL, we can then just:
- get standard deviation of an asset's price in the past 3 months -> volatility for each asset
- get the weight for each asset -> TVL of each asset out of all the TVL in a Safe
- sum up the weighted average of each asset in the Safe
- Top 3 Assets’ Concentration Ratio: how much wealth is concentrated on the top 3 assets -- TVL for top 3 assets / total TVL in the Safe
