/*
Putting all the point metrics (as opposed to trend that involves time) we have built so far 
--> decentralization (+ age (days since creation)) --> https://dune.com/queries/4456257
    - how many signers
    - what’s the threshold 
    - ratio of threshold / signers 
    - days since creation [meta]
--> usage/activeness --> https://dune.com/queries/4468423
    - average monthly num txn in the past (finished) n months
    - total num trnx in the past (finished) n months
    - average monthly volume in the past (finished) n months
    - total volume transacted in the pas t (finished) n months
    - percent volume stablecoin
--> TVL & diversification --> https://dune.com/queries/4511116
    - TVL (USD)
    - Stablecoin v Non’s TVL
    - Percent TVL stablecoin
    - num assets
    - Top n assets’ concentration ratio

--> dynamically helping certain metrics to be bucketed as more meaningful categorie 
    - https://dune.com/queries/1991151
    - * Note that for now adding this "dynamically" has memory limit, so for now hard coding in the numbers
*/

SELECT 
    tvl_div.safe_address
    -- Create clickable etherscan link
    , concat(
        '<a href="', 
        get_chain_explorer.explorer, 
        '/address/', 
        cast(tvl_div.safe_address as varchar), 
        '" target = "blank">', 
        cast(tvl_div.safe_address as varchar), 
        '</a>'
    )

    -- activeness & usage 
    , CASE 
        when COALESCE(act_usg.avg_monthly_transactions, 0) <= 2 then 'Hands Off'
        when act_usg.avg_monthly_transactions <= 15 then 'Slow and Steady'
        else 'Busy Bees'
      end as avg_monthly_num_txn_category
    , COALESCE(act_usg.avg_monthly_transactions, 0) as avg_monthly_num_txn
    , COALESCE(act_usg.total_transactions, 0) as total_prev_n_month_num_txn

    -- volume categories
    , CASE 
        when COALESCE(act_usg.total_usd_volume, 0) <= 200000 then 'Penny Pinchers'
        when act_usg.total_usd_volume <= 2000000 then 'Smart Savers'
        else 'Midas Touch'
      end as volume_category
    , COALESCE(act_usg.total_usd_volume, 0) as total_usd_volume
    , COALESCE(act_usg.avg_monthly_usd_volume, 0) as avg_monthly_usd_volume
    , COALESCE(act_usg.stablecoin_volume_percentage, 0) as stablecoin_volume_percentage

    -- TVL & diversification (updated to match your TVL query column names)
    , COALESCE(tvl_div.tvl, 0) as tvl
    , CASE 
        when COALESCE(tvl_div.tvl, 0) <= 100000 then 'Struggling'
        when tvl_div.tvl <= 1000000 then 'Balling on Budget'
        else 'Living the Dream'
      end as tvl_category
    , COALESCE(tvl_div.stablecoin_tvl, 0) as stablecoin_tvl
    , COALESCE(tvl_div.non_stablecoin_tvl, 0) as non_stablecoin_tvl
    , COALESCE(tvl_div.percent_tvl_stablecoins, 0) as percent_tvl_stablecoin  -- Updated from percent_tvl_stablecoin
    , COALESCE(tvl_div.num_assets, 0) as num_assets
    , COALESCE(tvl_div.hhi, 0) as hhi
    , CASE 
        when COALESCE(tvl_div.hhi, 0) < 1500 then 'Diversified'
        when tvl_div.hhi < 2500 then 'Medium'
        else 'Concentrated'
      end as hhi_category
    , COALESCE(tvl_div.weighted_avg_volatility_of_assets, 0) as weighted_avg_volatility  -- Updated from weighted_avg_volatility
    , CASE 
        when COALESCE(tvl_div.weighted_avg_volatility_of_assets, 0) < 1 then 'Serene Sailboat'
        when tvl_div.weighted_avg_volatility_of_assets < 10 then 'Bumpy Ride'
        else 'Roller Coaster'
      end as volatility_category
    , COALESCE(tvl_div.top_n_asset_concentration_ratio, 0) as top_3_concentration  -- Updated from top_3_concentration

    -- decentralization metrics
    , COALESCE(dec.num_owners, 0) as num_owners
    , COALESCE(dec.threshold_ratio, 0) as threshold_ratio
    , COALESCE(dec.days_since_creation, 0) as days_since_creation
    , dec.threshold
    , dec.all_signers
FROM query_4511116 tvl_div
LEFT JOIN query_4468423 act_usg 
    ON tvl_div.safe_address = act_usg.safe_address 
LEFT JOIN query_4456257 dec 
    ON tvl_div.safe_address = dec.safe_address
LEFT JOIN query_1747157 get_chain_explorer 
    ON get_chain_explorer.chain = 'ethereum'
WHERE tvl_div.tvl > 1000 
    OR act_usg.total_usd_volume > 1000

-- IDEAS 
/*
Trend of liquidity over time 
Trend of top tokens over time see if percent changed 

*/
