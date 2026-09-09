-- Weekly economic indicators at store + date grain (no department here —
-- these factors are store-wide, not department-specific).
-- Markdown columns are frequently null (no promotion running that week);
-- coalesced to 0 so downstream sums/joins don't silently drop rows.

select
    store::number                       as store_id,
    date::date                          as sales_date,
    temperature::number(6,2)            as temperature,
    fuel_price::number(6,3)             as fuel_price,
    coalesce(markdown1::number(12,2), 0) as markdown1,
    coalesce(markdown2::number(12,2), 0) as markdown2,
    coalesce(markdown3::number(12,2), 0) as markdown3,
    coalesce(markdown4::number(12,2), 0) as markdown4,
    coalesce(markdown5::number(12,2), 0) as markdown5,
    cpi::number(10,4)                   as cpi,
    unemployment::number(6,3)           as unemployment,
    isholiday::boolean                  as is_holiday
from {{ source('raw', 'raw_economic') }}