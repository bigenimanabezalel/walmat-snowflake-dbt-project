-- stores.csv has no Dept column, but the spec's Walmart_store_dim grain is
-- Store + Dept. This model builds that grain by taking every distinct
-- Store-Dept combination that has ever appeared in sales, and joining in
-- that store's current type/size from stg_walmart__stores.
--
-- This is the input to the SCD2 snapshot (snapshots/snap_walmart_store_dim.sql)
-- -- every dbt run, if a store's type/size changes, the snapshot versions it.

select
    sales.store_id,
    sales.dept_id,
    stores.store_type,
    stores.store_size
from (select distinct store_id, dept_id from {{ ref('stg_walmart__sales') }}) sales
left join {{ ref('stg_walmart__stores') }} stores
    on sales.store_id = stores.store_id