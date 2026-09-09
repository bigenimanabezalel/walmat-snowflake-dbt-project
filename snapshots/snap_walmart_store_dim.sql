{% snapshot snap_walmart_store_dim %}

{{
    config(
        target_schema='staging',
        unique_key="store_id || '-' || dept_id",
        strategy='check',
        check_cols=['store_type', 'store_size'],
    )
}}

-- This IS the SCD2 mechanism the spec asks for:
-- run `dbt snapshot` on every load. If store_type or store_size changes
-- for a given store_id+dept_id, dbt automatically:
--   1. closes the old row  (sets dbt_valid_to = now)
--   2. inserts a new row   (dbt_valid_from = now, dbt_valid_to = null)
-- dbt_valid_from/dbt_valid_to are exactly the "version out the old record /
-- insert new version" behaviour described in the project doc.

select * from {{ ref('stg_walmart__store_dept') }}

{% endsnapshot %}