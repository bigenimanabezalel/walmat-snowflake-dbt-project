-- One row per store: current type and size, as provided by stores.csv.
-- No department in this source, so the store dimension grain (store+dept)
-- is completed by joining to stg_walmart__sales, which is the only source
-- that carries the Store-Dept combinations.

select
    store::number        as store_id,
    type::varchar         as store_type,
    size::number          as store_size
from {{ source('raw', 'raw_stores') }}
