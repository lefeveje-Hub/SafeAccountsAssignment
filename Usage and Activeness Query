/* 

Time span: previous finished 3 months
Frequency
- Total # txns 
- Avg monthly # txns
Volume 
- Total USD volume
- Percent volume in stablecoins (refer to this query https://dune.com/queries/1984803 to see how stablecoins are defined)
- Avg monthly USD volume

Logic
- define Safes we are investigating
- transaction side of things for frequency - how many transactions in total have passed through this Safe
- volume
    - token flow (ETH and ERC20 tokens)
        - in and out flow are both counted as positive numbers (absolute USD value)
        - Eth value
        - ERC20 transfer events
    - adjust USD price, use prices.usd
- put everything together
*/

WITH safe_addresses AS (
    SELECT safe_address 
    FROM query_1976487 
    WHERE creation_time > now() - INTERVAL '6' MONTH
    
), 
txn AS (
    SELECT 
        "to" as safe_address,
        approx_distinct(tx_hash) as total_prev_n_month_num_txn,
        CAST(approx_distinct(tx_hash) AS double) / 3 as avg_monthly_num_txn
    FROM ethereum.traces t
    WHERE tx_success
        AND EXISTS (
            SELECT 1 
            FROM safe_addresses s 
            WHERE s.safe_address = t."to"
        )
        AND block_time >= date_add('MONTH', -3, date_trunc('MONTH', now())) 
        AND block_time < date_trunc('MONTH', now())
    GROUP BY 1
), 
eth_transfer_times AS (
    SELECT 
        date_add('MONTH', -3, date_trunc('MONTH', now())) as start_time,
        date_trunc('MONTH', now()) as end_time
),
eth_vol AS (
    SELECT safe_address, sum(eth_amt) as amt
    FROM (
        SELECT 
            "to" as safe_address,
            sum(value_decimal) as eth_amt
        FROM transfers_ethereum.eth t
        CROSS JOIN eth_transfer_times ett
        WHERE EXISTS (
            SELECT 1 
            FROM safe_addresses s 
            WHERE s.safe_address = t."to"
        )
        AND tx_block_time >= ett.start_time
        AND tx_block_time < ett.end_time
        GROUP BY 1

        UNION ALL 

        SELECT 
            "from" as safe_address,
            sum(value_decimal) as eth_amt
        FROM transfers_ethereum.eth t
        CROSS JOIN eth_transfer_times ett
        WHERE EXISTS (
            SELECT 1 
            FROM safe_addresses s 
            WHERE s.safe_address = t."from"
        )
        AND tx_block_time >= ett.start_time
        AND tx_block_time < ett.end_time
        GROUP BY 1
    ) combined
    GROUP BY 1
),
erc20_volume AS (
    SELECT 
        t.contract_address,
        t."to" as safe_address,
        abs(sum(CAST(t.value AS double) / power(10, COALESCE(tk.decimals, 18)))) as amount
    FROM erc20_ethereum.evt_transfer t
    CROSS JOIN eth_transfer_times ett
    LEFT JOIN tokens_ethereum.erc20 tk 
        ON tk.contract_address = t.contract_address
    WHERE EXISTS (
        SELECT 1 
        FROM safe_addresses s 
        WHERE s.safe_address = t."to"
    )
    AND evt_block_time >= ett.start_time
    AND evt_block_time < ett.end_time
    GROUP BY 1, 2
),
stablecoin_addresses AS (
    SELECT TRY_CAST(address AS varbinary) as contract_address 
    FROM (VALUES
        ('0xdac17f958d2ee523a2206206994597c13d831ec7'), -- USDT
        ('0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48'), -- USDC
        ('0x6b175474e89094c44da98b954eedeac495271d0f'), -- DAI
        ('0x4fabb145d64652a948d72533023f6e7a623c7c53'), -- BUSD
        ('0x8e870d67f660d95d5be530380d0ec0bd388289e1')  -- PAX
    ) as stables(address)
),
all_assets AS (
    -- ERC20 tokens
    SELECT 
        p.symbol as token_symbol,
        erc20.contract_address as token_address,
        erc20.safe_address,
        erc20.amount as sum_native_amount,
        erc20.amount * p.price as sum_usd_amount,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM stablecoin_addresses sa 
                WHERE sa.contract_address = erc20.contract_address
            ) THEN 'stablecoin'
            ELSE 'non-stablecoin'
        END as category
    FROM erc20_volume erc20
    INNER JOIN prices.usd p 
        ON p.contract_address = erc20.contract_address
        AND p.blockchain = 'ethereum'
    
    UNION ALL
    
    -- ETH
    SELECT 
        'ETH' as token_symbol,
        TRY_CAST('0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' AS varbinary) as token_address,
        eth.safe_address,
        eth.amt as sum_native_amount,
        eth.amt * p.price as sum_usd_amount,
        'non-stablecoin' as category
    FROM eth_vol eth
    INNER JOIN prices.usd p 
        ON p.contract_address = TRY_CAST('0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2' AS varbinary) -- WETH
        AND p.blockchain = 'ethereum'
)

-- Final combined metrics
SELECT 
    t.safe_address,
    t.total_prev_n_month_num_txn as total_transactions,
    t.avg_monthly_num_txn as avg_monthly_transactions,
    COALESCE(v.total_usd_volume, 0) as total_usd_volume,
    COALESCE(v.avg_monthly_usd_volume, 0) as avg_monthly_usd_volume,
    COALESCE(v.stablecoin_percentage, 0) as stablecoin_volume_percentage
FROM txn t
LEFT JOIN (
    SELECT 
        safe_address,
        sum(sum_usd_amount) as total_usd_volume,
        sum(sum_usd_amount) / 3 as avg_monthly_usd_volume,
        100.0 * sum(CASE WHEN category = 'stablecoin' THEN sum_usd_amount ELSE 0 END) / 
            NULLIF(sum(sum_usd_amount), 0) as stablecoin_percentage
    FROM all_assets
    GROUP BY 1
) v ON t.safe_address = v.safe_address
ORDER BY total_usd_volume DESC NULLS LAST
