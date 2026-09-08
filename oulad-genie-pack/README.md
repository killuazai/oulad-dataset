# OULAD Genie Pack

This pack creates two separate governed Genie spaces:

1. **OULAD Business Analytics Genie** — learner outcomes, engagement, assessment performance, demographics, and rule-based risk.
2. **OULAD Data Quality Genie** — current quality health, dimensions, datasets, problems, owners, history, and volume checks.

Keeping the spaces separate prevents business questions from being answered with operational DQ tables and keeps the context smaller, cheaper, and easier to govern.

## Run order

1. Run the repository's full pipeline through `13_validate_analytics.sql`.
2. Run `00_prepare_genie_sources.sql` once. Run it again after changing the view definitions; it is idempotent.
3. In Databricks, create two Genie spaces/agents and attach a running SQL warehouse.
4. Add only the objects listed in each instruction file.
5. Paste the corresponding general instructions into each space.
6. Add the matching question/SQL pairs from the example SQL files.
7. Test every recommended sample question and save verified answers as benchmarks where useful.

## Dashboard relationship

Genie is the natural-language question layer; the two SQL dashboards remain the fixed monitoring layer.

- Business dashboard: KPI cards for enrollments/outcomes, engagement by result, weekly activity, demographic outcome comparisons, assessment performance, and rule-based risk.
- Data-quality dashboard: overall health, dimension score, dataset score, current problem table, per-layer history, and source-volume history.

## Important repository finding

The current validation notebooks each declare a new `dq_run_id`. The existing repository view `dq_latest_check_results` ranks all runs globally, so it can expose only the last completed layer rather than the latest state of every layer.

The `genie_latest_check_results` view in this pack safely selects the latest run separately for Bronze, Silver, Gold, and Analytics. Its dependent Genie views therefore provide one current cross-layer snapshot without pretending the validators share one run ID.

## Files

- `00_prepare_genie_sources.sql` — creates all governed sources used by both spaces.
- `01_business_analytics_examples.sql` — verified-style business question/SQL examples.
- `02_data_quality_examples.sql` — verified-style DQ question/SQL examples.
- `BUSINESS_GENIE_INSTRUCTIONS.md` — objects, definitions, guardrails, and sample questions.
- `DATA_QUALITY_GENIE_INSTRUCTIONS.md` — DQ meanings, aggregation rules, guardrails, and sample questions.

## Cost and reliability choices

- Genie reads small, flat aggregate views rather than reconstructing star-schema joins for every question.
- Business and DQ contexts are isolated.
- Current DQ queries scan only the latest run per layer after the view is materialized by the SQL warehouse optimizer.
- Historical queries remain available but are used only when explicitly requested.
- Rates, grains, and risk interpretation are stated explicitly to reduce ambiguous answers.

