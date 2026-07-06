-- Staging model: one row per NYC green taxi trip (January 2024).
-- Renames source columns, adds derived columns, and filters bad rows.
-- Downstream: fct_daily_borough_stats joins this to stg_zones.

SELECT
    -- TODO: select the columns you need for the mart:
    --   pickup_datetime, pickup_location_id, fare_amount, tip_amount, trip_distance
    --
    -- TODO: add tip_pct using {{ safe_divide('tip_amount', 'fare_amount') }}
    --
    -- TODO: filter out rows where pickup_location_id IS NULL or fare_amount < 0

FROM {{ source('nyc_taxi', 'raw_trips') }}
