-- Walmart_store_dim: SCD Type 2.
-- Thin wrapper over the dbt snapshot (snap_walmart_store_dim) that renames
-- dbt's snapshot metadata columns to the field names in the project spec,
-- and surfaces a current-row flag for convenience joins in the fact model.

select
    store_id,
    dept_id,
    store_type,
    store_size,
    dbt_valid_from                                  as insert_date,
    dbt_valid_to                                     as update_date,
    dbt_valid_from                                   as vrsn_start_date,
    dbt_valid_to                                     as vrsn_end_date,
    case when dbt_valid_to is null then true else false end as is_current
from {{ ref('snap_walmart_store_dim') }}
