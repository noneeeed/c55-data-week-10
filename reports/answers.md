# Business Question Answers

Queries run against `dev_<your_name>.fct_daily_borough_stats`.

## Q1: Highest total `total_fare` across the whole loaded dataset

**SQL:**

```sql
-- TODO: query fct_daily_borough_stats grouped by pickup_borough, sum total_fare, order DESC
```

**Result:** TODO

**Interpretation:** TODO (one sentence)

---

## Q2: Day with the highest overall `trip_count`

**SQL:**

```sql
-- TODO: query fct_daily_borough_stats grouped by pickup_date, sum trip_count, order DESC LIMIT 1
```

**Result:** TODO

**Interpretation:** TODO (one sentence)

---

## Q3: Highest `avg_tip_pct` for any (borough, day) combination

**SQL:**

```sql
-- TODO: query fct_daily_borough_stats order by avg_tip_pct DESC LIMIT 5
```

**Result:** TODO

**Interpretation:** TODO — note whether any avg_tip_pct > 1 rows appear and what causes them

---

## Q4: Median daily `trip_count` for Manhattan vs Brooklyn

**SQL:**

```sql
-- TODO: use percentile_cont(0.5) WITHIN GROUP (ORDER BY trip_count) filtered by borough
```

**Result:** TODO

**Interpretation:** TODO (one sentence on the ratio)
