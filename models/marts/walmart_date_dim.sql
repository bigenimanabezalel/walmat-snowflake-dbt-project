-- Walmart_date_dim: SCD Type 1 (upsert).
-- One row per distinct calendar date seen across the sales and economic
-- feeds. Uses dbt's native "merge" incremental strategy on Snowflake:
-- new dates are inserted, and if a date's is_holiday flag ever disagrees
-- with what's already stored, the existing row is overwritten in place
-- (update_date refreshed) rather than versioned -- that's what makes this
-- SCD1 rather than SCD2.

{{ config(
    materialized='incremental',
    unique_key='date_id',
    incremental_strategy='merge'
) }}

with all_dates as (
    select sales_date, is_holiday from {{ ref('stg_walmart__sales') }}
    union
    select sales_date, is_holiday from {{ ref('stg_walmart__economic') }}
),

deduped as (
    select
        sales_date,
        -- if any source flags a date as holiday, treat the date as holiday
        max(is_holiday::int)::boolean as is_holiday
    from all_dates
    group by sales_date
)

select
    to_number(to_char(sales_date, 'YYYYMMDD')) as date_id,  -- stable surrogate key, e.g. 20100205
    sales_date                                  as store_date,
    is_holiday,
    current_timestamp()                         as insert_date,
    current_timestamp()                         as update_date
from deduped
