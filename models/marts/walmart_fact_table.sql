-- Walmart_fact_table
-- Grain: one row per Store + Dept + Date.
--
-- Joins:
--   - stg_walmart__sales      -> Weekly_Sales, base grain
--   - stg_walmart__economic   -> Temperature/Fuel/CPI/Unemployment/Markdowns
--                                 (store+date grain; same value applies to
--                                 every dept in that store for that week)
--   - walmart_date_dim        -> date_id surrogate key
--   - walmart_store_dim (SCD2)-> matched to the store_dim version that was
--                                 EFFECTIVE on the sales date, and the
--                                 fact row inherits that version's
--                                 vrsn_start_date/vrsn_end_date. This is
--                                 what versions the fact table in step with
--                                 the store dimension per the project spec:
--                                 if store_dim changes, old fact rows for
--                                 dates before the change keep the old
--                                 version window, and any new load will
--                                 pick up the new version's window going
--                                 forward.

with sales as (
    select * from {{ ref('stg_walmart__sales') }}
),

economic as (
    select * from {{ ref('stg_walmart__economic') }}
),

date_dim as (
    select date_id, store_date from {{ ref('walmart_date_dim') }}
),

store_dim as (
    select * from {{ ref('walmart_store_dim') }}
)

select
    sales.store_id,
    sales.dept_id,
    date_dim.date_id,
    store_dim.store_size,
    sales.weekly_sales                        as store_weekly_sales,
    economic.fuel_price,
    economic.temperature                      as store_temperature,
    economic.unemployment,
    economic.cpi,
    economic.markdown1,
    economic.markdown2,
    economic.markdown3,
    economic.markdown4,
    economic.markdown5,
    current_timestamp()                       as insert_date,
    current_timestamp()                       as update_date,
    store_dim.vrsn_start_date,
    store_dim.vrsn_end_date
from sales
inner join date_dim
    on sales.sales_date = date_dim.store_date
left join economic
    on sales.store_id = economic.store_id
    and sales.sales_date = economic.sales_date
left join store_dim
    on sales.store_id = store_dim.store_id
    and sales.dept_id = store_dim.dept_id
    -- pick the store_dim version that was active on the sales date
    and sales.sales_date >= store_dim.vrsn_start_date
    and (sales.sales_date < store_dim.vrsn_end_date or store_dim.vrsn_end_date is null)
