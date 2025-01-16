Decentralization Query

/*
Metrics
- # Signers / Owners 
- Threshold 
- Threshold ratio (threshold # required to transact / total # signers) 
- Days since creations
- List/Array of all signers 

Steps
- get all safe addresses we care about -- safe created in the past 6 months
- # signers at the creation stage (when it was set up )
- signers added events
- signers removed events
-> data manipulation to get the metrics

*/
WITH setup AS (
  SELECT
    creation_time,
    safe_address AS address,
    threshold,
    u.unnested_owners AS owner
  FROM query_1976487 CROSS JOIN UNNEST(owners_array) AS u(unnested_owners)
  WHERE
    creation_time > CURRENT_TIMESTAMP - INTERVAL '6' month
)
, add_owner AS (
    SELECT evt_block_time AS block_time, contract_address AS address, owner
    FROM gnosis_safe_ethereum.Safev0_1_0_evt_AddedOwner ao
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ao.contract_address = setup.address)
UNION ALL 
    SELECT evt_block_time AS block_time, contract_address AS address, owner
    FROM gnosis_safe_ethereum.Safev1_0_0_evt_AddedOwner ao
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ao.contract_address = setup.address)
UNION ALL 
    SELECT evt_block_time AS block_time, contract_address AS address, owner
    FROM gnosis_safe_ethereum.Safev1_1_0_evt_AddedOwner ao
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ao.contract_address = setup.address)
UNION ALL 
    SELECT evt_block_time AS block_time, contract_address AS address, owner
    FROM gnosis_safe_ethereum.Safev1_1_1_evt_AddedOwner ao
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ao.contract_address = setup.address)
UNION ALL 
    SELECT evt_block_time AS block_time, contract_address AS address, owner
    FROM gnosis_safe_ethereum.GnosisSafev1_3_0_evt_AddedOwner ao
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ao.contract_address = setup.address)
UNION ALL 
    SELECT creation_time AS block_time, address, owner
    FROM setup
)
, remove_owner as (
    SELECT evt_block_time AS block_time, contract_address as address, owner
    FROM gnosis_safe_ethereum.Safev0_1_0_evt_RemovedOwner ro 
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ro.contract_address = setup.address)
UNION ALL 
    SELECT evt_block_time AS block_time, contract_address as address, owner
    FROM gnosis_safe_ethereum.Safev1_0_0_evt_RemovedOwner ro 
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ro.contract_address = setup.address)
UNION ALL 
    SELECT evt_block_time AS block_time, contract_address as address, owner
    FROM gnosis_safe_ethereum.Safev1_1_0_evt_RemovedOwner ro 
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ro.contract_address = setup.address)
UNION ALL 
    SELECT evt_block_time AS block_time, contract_address as address, owner
    FROM gnosis_safe_ethereum.Safev1_1_1_evt_RemovedOwner ro 
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ro.contract_address = setup.address)
UNION ALL 
    SELECT evt_block_time AS block_time, contract_address as address, owner
    FROM gnosis_safe_ethereum.GnosisSafev1_3_0_evt_RemovedOwner ro 
    WHERE evt_block_time > now() - INTERVAL '6' month
        AND exists (SELECT 1 FROM setup WHERE ro.contract_address = setup.address)
)
SELECT 
    a.address AS safe_address, 
    s.creation_time,
    s.threshold,
    date_diff('day', s.creation_time, now()) as days_since_creation,
    cast(s.threshold as double) /COUNT(distinct a.owner) AS threshold_ratio, 
    COUNT(distinct a.owner) AS num_owners, 
    array_agg(distinct a.owner) AS all_signers
FROM add_owner a
LEFT JOIN remove_owner r ON a.address = r.address AND a.owner = r.owner AND a.block_time < r.block_time
LEFT JOIN setup s ON s.address = a.address
WHERE r.owner IS null
GROUP BY 1,2,3,4
ORDER BY 2
