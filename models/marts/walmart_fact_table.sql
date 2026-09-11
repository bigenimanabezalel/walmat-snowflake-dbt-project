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

-- with sales as (
--     select * from {{ ref('stg_walmart__sales') }}
-- ),

-- economic as (
--     select * from {{ ref('stg_walmart__economic') }}
-- ),

-- date_dim as (
--     select date_id, store_date from {{ ref('walmart_date_dim') }}
-- ),

-- store_dim as (
--     select * from {{ ref('walmart_store_dim') }}
-- )

-- select
--     sales.store_id,
--     sales.dept_id,
--     date_dim.date_id,
--     store_dim.store_size,
--     sales.weekly_sales                        as store_weekly_sales,
--     economic.fuel_price,
--     economic.temperature                      as store_temperature,
--     economic.unemployment,
--     economic.cpi,
--     economic.markdown1,
--     economic.markdown2,
--     economic.markdown3,
--     economic.markdown4,
--     economic.markdown5,
--     current_timestamp()                       as insert_date,
--     current_timestamp()                       as update_date,
--     store_dim.vrsn_start_date,
--     store_dim.vrsn_end_date
-- from sales
-- inner join date_dim
--     on sales.sales_date = date_dim.store_date
-- left join economic
--     on sales.store_id = economic.store_id
--     and sales.sales_date = economic.sales_date
-- left join store_dim
--     on sales.store_id = store_dim.store_id
--     and sales.dept_id = store_dim.dept_id
--     -- pick the store_dim version that was active on the sales date
--     and sales.sales_date >= store_dim.vrsn_start_date
--     and (sales.sales_date < store_dim.vrsn_end_date or store_dim.vrsn_end_date is null)
-- =============================================================================================


-- Walmart_fact_table
-- Grain: one row per Store + Dept + Date.
--
-- Joins:
--   - stg_walmart__sales      -> Weekly_Sales, base grain
--   - stg_walmart__economic   -> Temperature/Fuel/CPI/Unemployment/Markdowns
--                                 (store+date grain; same value applies to
--                                 every dept in that store for that week)
--   - walmart_date_dim        -> date_id surrogate key
--   - walmart_store_dim (SCD2)-> matched to the CURRENT store_dim version
--                                 (is_current = true), not a date-range
--                                 match against vrsn_start_date/vrsn_end_date.
--
-- Why not date-range match against the sales date? Because the source
-- data (stores.csv) only ever provides ONE snapshot of store attributes --
-- there's no genuine history of store_type/store_size changing over time.
-- The SCD2 snapshot's dbt_valid_from is set to whenever `dbt snapshot`
-- was FIRST run (i.e. "now"), which is years after the 2010-2012 sales
-- dates in this dataset. A date-range join (sales_date >= vrsn_start_date)
-- would therefore never match anything, since every sales_date predates
-- the snapshot's own creation timestamp -- silently leaving store_size and
-- every downstream chart that depends on it entirely NULL.
--
-- Joining to the current version instead means: if store_type/store_size
-- genuinely changes in a future re-load (dbt snapshot creates a new
-- version), NEW fact rows going forward will pick up the new version.
-- Historical fact rows already loaded keep whatever version was current
-- when THEY were loaded (since insert_date/vrsn_* are set at load time,
-- not recalculated), which is the practical, correct behavior a
-- production run would produce -- and unlike the date-range join, it
-- actually returns data for this dataset's date range.

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
    where is_current = true
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