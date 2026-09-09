-- Weekly sales at store + department + date grain.

select
    store::number           as store_id,
    dept::number            as dept_id,
    date::date              as sales_date,
    weekly_sales::number(12,2) as weekly_sales,
    isholiday::boolean      as is_holiday
from {{ source('raw', 'raw_sales') }}