/*
TVL in USD
- All assets' TVL                         -- Total value of all assets held in the Safe wallet
- Stablecoin vs. Non-Stablecoins's TVL   -- Breakdown of value between stable (e.g., USDC) and volatile assets (e.g., ETH)
- Percent TVL in Stablecoins             -- Proportion of total value held in stablecoins, indicates risk appetite

Diversification
- Number of different Assets in the Safe  -- Count of unique tokens, measures basic portfolio diversity
- HHI (Herfindahl-Hirschman Index)       -- Measure of portfolio concentration (0-10000), lower = more diversified
- Top 3 Assets' Concentration Ratio       -- % of total value in 3 largest holdings, indicates concentration risk
- Weighted Average Volatility of Assets   -- Portfolio volatility weighted by each asset's value share

Logic Steps
- Targeted Safes                          -- Get Safes created in past 6 months on Ethereum
- Balance of Tokens (ETH & ERC20)         -- Calculate current holdings of ETH and tokens
- Sum tokens for TVL metrics              -- Aggregate balances, categorize stable/unstable, count assets
- Find asset volatilities                 -- Calculate 3-month price standard deviation for each asset
- Combine all metrics                     -- Join data and compute final portfolio metrics
*/

with safe_addresses as (
    select 
        safe_address 
    from query_1976487
    where creation_time > now() - interval '6' month
),

-- ETH Balance calculation
eth_balance as (
    with eth_in as (
        select 
            date_trunc('week', tx_block_time) as time,
            "to" as safe_address,
            sum(value_decimal) as eth_amt
        from transfers_ethereum.eth
        where exists (select 1 from safe_addresses where safe_address = "to")
            and tx_block_time > now() - interval '6' month
        group by 1,2
    ),
    eth_out as (
        select 
            date_trunc('week', tx_block_time) as time,
            "from" as safe_address,
            -1 * sum(value_decimal) as eth_amt
        from transfers_ethereum.eth
        where exists (select 1 from safe_addresses where safe_address = "from")
            and tx_block_time > now() - interval '6' month
        group by 1,2
    ),
    eth_both as (
        select * from eth_in
        union all 
        select * from eth_out
    )
    select 
        safe_address, 
        sum(eth_amt) as amt 
    from eth_both
    group by 1
),

-- ERC20 Balance calculation    
erc20_balance as (
    select 
        t.contract_address as token_address,
        t."to" as safe_address,
        sum(cast(t.value as double) / power(10, COALESCE(tk.decimals, 18))) as amt
    from erc20_ethereum.evt_transfer t
    left join tokens.erc20 tk 
        on tk.contract_address = t.contract_address
        and tk.blockchain = 'ethereum'
    where exists (select 1 from safe_addresses where safe_address = t."to")
        and t.evt_block_time > now() - interval '6' month
    group by 1,2
),

-- Combining ETH and ERC20 balances with prices
all_assets as (
    select 
        p.symbol as token_symbol,
        erc20.token_address,
        erc20.safe_address,
        case 
            when erc20.token_address in (select contract_address from query_1984803) then 'stablecoins'
            else 'non-stablecoins'
        end as category,
        erc20.amt as sum_native_amt,
        cast(erc20.amt as double) * p.price as sum_usd_amt
    from erc20_balance erc20
    inner join prices.usd_latest p 
        on p.contract_address = erc20.token_address
        and p.blockchain = 'ethereum'
    
    union all 
    
    select 
        'ETH' as token_symbol,
        0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee as token_address,
        eth.safe_address,
        'non-stablecoins' as category,
        eth.amt as sum_native_amt,
        eth.amt * p.price as sum_usd_amt 
    from eth_balance eth 
    inner join prices.usd_latest p 
        on p.contract_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        and p.blockchain = 'ethereum'
),

-- Calculate basic TVL metrics
summing as (
    select 
        safe_address,
        count(token_address) as num_assets,
        sum(sum_usd_amt) as tvl,
        sum(sum_usd_amt) filter (where category = 'stablecoins') as stablecoin_tvl,
        sum(sum_usd_amt) filter (where category = 'non-stablecoins') as non_stablecoin_tvl,
        sum(sum_usd_amt) filter (where category = 'stablecoins') / nullif(sum(sum_usd_amt), 0) as percent_tvl_stablecoins
    from all_assets
    group by 1 
),

-- Calculate asset volatility (3-month standard deviation)
all_assets_std as (
    select 
        contract_address as token_address,
        stddev_samp(price) as stdev_price
    from (
        select 
            p.contract_address,
            p.minute,
            p.price
        from prices.usd p 
        where p.blockchain = 'ethereum'
            and exists (select 1 from all_assets a where a.token_address = p.contract_address)
            and p.minute > now() - interval '3' month 
        order by 1,2 
    ) t
    group by 1
    
    union all 

    -- ETH volatility using WETH as proxy
    select 
        0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee as token_address,
        stddev_samp(price) as stdev_price
    from (
        select 
            p.minute,
            p.price
        from prices.usd p 
        where p.blockchain = 'ethereum'
            and p.contract_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
            and p.minute > now() - interval '3' month 
        order by 1,2 
    ) t2
    group by 1
),

-- Combine metrics and calculate HHI and weighted volatility
join1 as (
    select 
        s.safe_address,
        s.num_assets,
        s.tvl,
        s.stablecoin_tvl,
        s.non_stablecoin_tvl,
        s.percent_tvl_stablecoins,
        sum(pow(a.sum_usd_amt/s.tvl*100, 2)) as hhi,
        sum(a.sum_usd_amt/s.tvl * std.stdev_price) as weighted_avg_volatility_of_assets
    from summing s
    left join all_assets a on a.safe_address = s.safe_address
    left join all_assets_std std on std.token_address = a.token_address
    where s.tvl > 0.001  -- Filter out noise
    group by 1,2,3,4,5,6
),

-- Rank assets by value for concentration ratio
ranked as (
    select 
        safe_address,
        token_address,
        sum_usd_amt,
        row_number() over (partition by safe_address order by sum_usd_amt desc) as rn 
    from all_assets
)

-- Final output with all metrics
select 
    j.safe_address,
    j.num_assets,
    j.tvl,
    j.stablecoin_tvl,
    j.non_stablecoin_tvl,
    j.percent_tvl_stablecoins,
    case when hhi >= 10000 then 10000 else hhi end as hhi,
    j.weighted_avg_volatility_of_assets,
    sum(r.sum_usd_amt) / j.tvl as top_n_asset_concentration_ratio
from join1 j 
left join ranked r 
    on r.safe_address = j.safe_address
    and r.rn <= 3  -- Top 3 assets
group by 1,2,3,4,5,6,7,8
