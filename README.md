# Week 10 Assignment: Daily Borough Stats Mart

HackYourFuture Data Track, Week 10. The full brief (business question, tasks, and submission steps) lives in the curriculum: **Week 10 → Assignment** in the HackYourFuture learning platform. Read it first; this repo only gets you started.

## What you build

A dbt Core project called `nyc_taxi_borough_daily` that produces a mart at the grain **one row per (pickup_borough, pickup_date)** for the NYC Green Taxi January 2024 dataset already loaded in the shared Azure PostgreSQL instance.

## What this repo gives you

This repo is a **ready-to-run dbt project**: the project config is wired up and every model, test, and report is a TODO stub for you to fill in. You do not scaffold anything: your job is to write the models, tests, and docs.

```text
.                                <- this repo is the dbt project root
├── dbt_project.yml              <- ready to run: staging = view, marts = table
├── packages.yml                 <- TODO stub: declare dbt_utils (Task 5)
├── profiles.yml.example         <- connection template: copy to profiles.yml
├── macros/
│   └── safe_divide.sql          <- TODO stub: implement the macro
├── models/
│   ├── staging/
│   │   ├── _sources.yml         <- TODO stub: confirm the source declaration
│   │   ├── _stg_trips.yml       <- TODO stub: descriptions + tests
│   │   ├── _stg_zones.yml       <- TODO stub: descriptions + tests
│   │   ├── stg_trips.sql        <- TODO stub: implement staging model
│   │   └── stg_zones.sql        <- TODO stub: implement staging model
│   └── marts/
│       ├── _fct_daily_borough_stats.yml  <- TODO stub: grain + descriptions + tests
│       └── fct_daily_borough_stats.sql   <- TODO stub: implement the mart
├── tests/
│   └── assert_avg_tip_pct_within_bounds.sql  <- TODO stub: singular test
├── docs/                        <- your lineage.png screenshot goes here (Task 6)
├── reports/
│   └── answers.md               <- template: four business questions (Task 7)
└── AI_ASSIST.md                 <- template: document one LLM session (Task 8)
```

## Task 1: connect to the shared database

The project is already initialised, so Task 1 is just pointing it at the database with your personal schema.

1. Copy the connection template and set your personal schema:

```bash
cp profiles.yml.example profiles.yml
# edit profiles.yml: replace <your_name> so schema reads dev_<your_name>
```

2. Export the connection env vars (values are in the class vault; ask your mentor if you are missing them):

```bash
export PG_HOST=...
export PG_USER=...
export PG_PASSWORD=...
export PG_DBNAME=postgres
```

3. Verify: `dbt debug` must end with `All checks passed!`.

`profiles.yml` is git-ignored. Never commit it: the autograder treats a committed `profiles.yml` as a blocker.

## Check your score locally

The autograder runs static checks (required files, secrets hygiene, SQL patterns, docs artefacts):

```bash
bash .hyf/test.sh
cat .hyf/score.json
```

Passing score: 60/100. CI runs the same script on your PR, plus a `dbt parse` check that validates your project structure and Jinja without a database connection.

## Submitting

Follow the Submission section of the assignment chapter: branch `week10/your-name`, commit, push, open a PR, and paste your `dbt build` summary line in the PR description.
