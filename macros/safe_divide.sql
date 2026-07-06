-- safe_divide(numerator, denominator)
-- Returns numerator / denominator, or NULL when denominator is 0 or NULL.
-- Use for tip_pct = tip_amount / fare_amount and similar ratio columns.

{% macro safe_divide(numerator, denominator) %}
    -- TODO: implement the macro body.
    -- Use NULLIF(denominator, 0) to avoid division-by-zero errors.
    -- Return only the SQL expression (no SELECT, no semicolon).
    NULL
{% endmacro %}
