#!/usr/bin/env bash
# Week 10 autograder: static analysis only.
# dbt build requires a live Azure PostgreSQL connection that CI cannot reach.
# The grader checks file presence, SQL patterns, YAML content, and doc artefacts.
#
# Total points: 100. Passing score: 60.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/grader_lib.sh"

cat > "$SCRIPT_DIR/score.json" <<'INIT'
{"score": 0, "pass": false, "passingScore": 60}
INIT

score=0
PASSING=60

# Helper: true when a file has real content and no *unreplaced* TODO stub.
# The scaffold ships "-- TODO:" guide comments inside the starter models; a
# student who writes the model below the comment and leaves the comment in
# place is done, not stubbed. SQL line-comments are stripped before the check,
# and only a line whose content *begins* with TODO (an unreplaced markdown/YAML
# placeholder like "TODO: your answer") marks a file a stub.
file_is_filled() {
  local f="$1"
  [[ -s "$f" ]] || return 1
  local body
  body="$(sed -E 's/--.*$//' "$f" | grep -vE '^[[:space:]]*$')"
  [[ -n "$body" ]] || return 1
  if printf '%s\n' "$body" | grep -qiE '^[[:space:]]*([#>*-]+[[:space:]]*)?TODO\b'; then
    return 1
  fi
  return 0
}

# Like `grep -qiE PATTERN FILE`, but on SQL with line-comments stripped, so a
# keyword that appears only inside a "-- TODO: add a JOIN" guide comment does
# NOT count as real SQL. Use this for every content check on a .sql deliverable.
sqlgrep() {
  sed -E 's/--.*$//' "$2" | grep -qiE "$1"
}

# ── Level 1 (10 pts): required files exist ──────────────────────────────────
l1=0
required_files=(
  "dbt_project.yml"
  "packages.yml"
  "profiles.yml.example"
  "macros/safe_divide.sql"
  "models/staging/_sources.yml"
  "models/staging/stg_trips.sql"
  "models/staging/stg_zones.sql"
  "models/marts/fct_daily_borough_stats.sql"
  "reports/answers.md"
  "AI_ASSIST.md"
)
missing=0
for f in "${required_files[@]}"; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    pass "found $f"
  else
    fail "missing required file: $f"
    ((missing += 1))
  fi
done
if ls "$REPO_ROOT/tests/"*.sql &>/dev/null 2>&1; then
  pass "found singular test in tests/"
else
  fail "no .sql file found in tests/ -- add at least one singular test"
  ((missing += 1))
fi
if [[ -s "$REPO_ROOT/docs/lineage.png" ]]; then
  pass "found docs/lineage.png"
else
  fail "docs/lineage.png missing -- run dbt docs generate + serve and screenshot the lineage graph"
  ((missing += 1))
fi
if [[ "$missing" -eq 0 ]]; then
  l1=10
fi
((score += l1))
pass "Level 1: required files ($l1/10 pts)"

# ── Level 2 (15 pts): secrets hygiene ───────────────────────────────────────
l2=0
gi="$REPO_ROOT/.gitignore"
ex="$REPO_ROOT/profiles.yml.example"

if [[ -f "$gi" ]] && grep -qE "^profiles\.yml$" "$gi"; then
  ((l2 += 5)); pass ".gitignore: profiles.yml excluded"
else
  fail ".gitignore must contain 'profiles.yml' on its own line"
fi

if [[ -f "$ex" ]] && grep -qE "env_var\(" "$ex"; then
  ((l2 += 5)); pass "profiles.yml.example: uses env_var() -- no hardcoded password"
else
  fail "profiles.yml.example must use env_var('PG_PASSWORD') instead of a hardcoded password"
fi

if [[ -f "$REPO_ROOT/profiles.yml" ]]; then
  fail "profiles.yml is committed -- BLOCKER: run: git rm --cached profiles.yml"
else
  ((l2 += 5)); pass "profiles.yml not committed (correctly git-ignored)"
fi
((score += l2))
pass "Level 2: secrets hygiene ($l2/15 pts)"

# ── Level 3 (20 pts): staging models ────────────────────────────────────────
l3=0
st="$REPO_ROOT/models/staging/stg_trips.sql"
sz="$REPO_ROOT/models/staging/stg_zones.sql"

if file_is_filled "$st" && sqlgrep "\{\{[[:space:]]*source\(" "$st"; then
  ((l3 += 4)); pass "stg_trips.sql: uses {{ source() }} reference"
else
  fail "stg_trips.sql: must use {{ source('nyc_taxi', 'raw_trips') }}"
fi

if file_is_filled "$st" && sqlgrep "pickup_location_id" "$st" && sqlgrep "IS NOT NULL|NOT NULL" "$st"; then
  ((l3 += 4)); pass "stg_trips.sql: filters NULL pickup_location_id"
else
  fail "stg_trips.sql: must filter WHERE pickup_location_id IS NOT NULL"
fi

if file_is_filled "$st" && sqlgrep "fare_amount" "$st" && sqlgrep ">=.*0|> -1" "$st"; then
  ((l3 += 4)); pass "stg_trips.sql: filters negative fares (fare_amount >= 0)"
else
  fail "stg_trips.sql: must filter WHERE fare_amount >= 0"
fi

if file_is_filled "$st" && sqlgrep "tip_pct|safe_divide" "$st"; then
  ((l3 += 4)); pass "stg_trips.sql: tip_pct column present"
else
  fail "stg_trips.sql: tip_pct column missing -- add {{ safe_divide('tip_amount', 'fare_amount') }} AS tip_pct"
fi

if file_is_filled "$sz" && sqlgrep "\{\{[[:space:]]*source\(" "$sz"; then
  ((l3 += 4)); pass "stg_zones.sql: uses {{ source() }} and is filled"
else
  fail "stg_zones.sql: must use {{ source('nyc_taxi', 'raw_zones') }}"
fi
((score += l3))
pass "Level 3: staging models ($l3/20 pts)"

# ── Level 4 (20 pts): mart model ─────────────────────────────────────────────
l4=0
mart="$REPO_ROOT/models/marts/fct_daily_borough_stats.sql"

if file_is_filled "$mart"; then
  ((l4 += 2)); pass "fct_daily_borough_stats.sql: file filled"

  if sqlgrep "\{\{[[:space:]]*ref\('stg_trips'\)" "$mart" && sqlgrep "\{\{[[:space:]]*ref\('stg_zones'\)" "$mart"; then
    ((l4 += 4)); pass "mart: ref() to both stg_trips and stg_zones"
  else
    fail "mart: must reference both {{ ref('stg_trips') }} and {{ ref('stg_zones') }}"
  fi

  if sqlgrep "(INNER|LEFT)?[[:space:]]*JOIN" "$mart"; then
    ((l4 += 4)); pass "mart: JOIN to zones present"
  else
    fail "mart: no JOIN -- must join stg_trips to stg_zones on pickup_location_id = location_id"
  fi

  if sqlgrep "GROUP[[:space:]]+BY" "$mart"; then
    ((l4 += 4)); pass "mart: GROUP BY present"
  else
    fail "mart: no GROUP BY -- must aggregate to (pickup_borough, pickup_date) grain"
  fi

  cols_ok=0
  for col in pickup_borough pickup_date trip_count total_fare avg_tip_pct avg_trip_distance; do
    if sqlgrep "$col" "$mart"; then
      ((cols_ok += 1))
    else
      fail "mart: required output column '$col' not found"
    fi
  done
  if [[ "$cols_ok" -eq 6 ]]; then
    ((l4 += 6)); pass "mart: all 6 required output columns present"
  elif [[ "$cols_ok" -ge 4 ]]; then
    ((l4 += 3)); warn "mart: $cols_ok/6 required columns present"
  fi
else
  fail "fct_daily_borough_stats.sql: still contains TODO stubs"
fi
((score += l4))
pass "Level 4: mart model ($l4/20 pts)"

# ── Level 5 (15 pts): tests ─────────────────────────────────────────────────
l5=0
mart_yml="$REPO_ROOT/models/marts/_fct_daily_borough_stats.yml"
singular_test=$(ls "$REPO_ROOT/tests/"*.sql 2>/dev/null | head -1 || true)

if [[ -f "$mart_yml" ]] && grep -qiE "unique_combination_of_columns" "$mart_yml"; then
  ((l5 += 5)); pass "mart YAML: dbt_utils.unique_combination_of_columns test present"
else
  fail "mart YAML: missing dbt_utils.unique_combination_of_columns on (pickup_borough, pickup_date)"
fi

stg_yml="$REPO_ROOT/models/staging/_stg_trips.yml"
if [[ -f "$stg_yml" ]] && grep -qiE "not_null" "$stg_yml"; then
  ((l5 += 5)); pass "staging YAML: not_null tests present"
else
  fail "staging YAML (_stg_trips.yml): not_null tests missing on key columns"
fi

if [[ -n "$singular_test" ]] && file_is_filled "$singular_test"; then
  if sqlgrep "\{\{[[:space:]]*ref\('fct_daily_borough_stats'\)" "$singular_test"; then
    ((l5 += 5)); pass "singular test: filled and references fct_daily_borough_stats"
  else
    ((l5 += 3)); pass "singular test: filled (does not reference fct_daily_borough_stats -- check)"
  fi
else
  fail "singular test: empty or still a TODO stub"
fi
((score += l5))
pass "Level 5: tests ($l5/15 pts)"

# ── Level 6 (10 pts): documentation ─────────────────────────────────────────
l6=0
mart_yml="$REPO_ROOT/models/marts/_fct_daily_borough_stats.yml"

if [[ -f "$mart_yml" ]] && grep -qiE "grain|one row per" "$mart_yml"; then
  if ! grep -B5 -A5 "grain\|one row per" "$mart_yml" | grep -qiE "TODO"; then
    ((l6 += 5)); pass "mart YAML: grain stated in model description"
  else
    fail "mart YAML: grain mentioned but description still has TODO -- fill it in"
  fi
else
  fail "mart YAML: model description must state the grain (one row per pickup_borough + pickup_date)"
fi

if [[ -f "$mart_yml" ]]; then
  filled_descs=$(grep "description:" "$mart_yml" | grep -v "TODO" | grep -cvE '^\s*description:\s*("")?\s*$' || true)
  if [[ "$filled_descs" -ge 4 ]]; then
    ((l6 += 5)); pass "mart YAML: $filled_descs column descriptions filled"
  elif [[ "$filled_descs" -ge 2 ]]; then
    ((l6 += 3)); warn "mart YAML: only $filled_descs column descriptions filled (target: all 6)"
  else
    fail "mart YAML: column descriptions are empty -- explain meaning and units for each column"
  fi
fi
((score += l6))
pass "Level 6: documentation ($l6/10 pts)"

# ── Level 7 (10 pts): business answers + AI log ─────────────────────────────
l7=0
ans="$REPO_ROOT/reports/answers.md"
ai="$REPO_ROOT/AI_ASSIST.md"

if file_is_filled "$ans"; then
  sql_blocks=$(grep -c "^\`\`\`sql" "$ans" 2>/dev/null || echo 0)
  if [[ "$sql_blocks" -ge 4 ]]; then
    ((l7 += 5)); pass "reports/answers.md: 4 SQL blocks present and filled"
  elif [[ "$sql_blocks" -ge 2 ]]; then
    ((l7 += 3)); warn "reports/answers.md: $sql_blocks SQL block(s) present (need 4)"
  else
    ((l7 += 2)); warn "reports/answers.md: filled but SQL blocks missing"
  fi
else
  fail "reports/answers.md: empty or still contains TODO stubs"
fi

if file_is_filled "$ai"; then
  chars=$(wc -c < "$ai" | tr -d ' ')
  if [[ "$chars" -ge 800 ]]; then
    ((l7 += 5)); pass "AI_ASSIST.md: filled (${chars} chars)"
  else
    ((l7 += 2)); warn "AI_ASSIST.md: present but brief (${chars} chars -- target 800+)"
  fi
else
  fail "AI_ASSIST.md: empty or still contains TODO stubs"
fi
((score += l7))
pass "Level 7: business answers + AI log ($l7/10 pts)"

# ── Final ─────────────────────────────────────────────────────────────────────
print_results "Week 10 Autograder"
write_score "$score" "$PASSING" "$SCRIPT_DIR/score.json"
