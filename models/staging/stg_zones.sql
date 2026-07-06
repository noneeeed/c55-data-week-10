-- Staging model: one row per TLC zone (265 zones).
-- Exposes location_id and borough for use as a lookup in the mart.

SELECT
    -- TODO: select location_id and borough from {{ source('nyc_taxi', 'raw_zones') }}

FROM {{ source('nyc_taxi', 'raw_zones') }}
