# Dashboard build and maintenance guide

The professor-required dashboard target is Metabase. Use `../metabase/README.md`,
`../metabase/dashboard_queries.sql`, and
`../metabase/data_quality_dashboard_queries.sql` for the submission. The Lakeview files
in this directory are retained as optional Databricks portfolio artifacts.

Run `notebooks/00_run_full_pipeline.sql` before refreshing either dashboard. The final runner step creates the `genie_*` views used by the exported dashboards.

## Business Analytics dashboard

Use `business_dashboard.sql` as the formula reference and apply `BUSINESS_DASHBOARD_REVISION_PROMPT.md` to the Databricks dashboard.

Required content:

1. Outcome and assessment KPI cards.
2. Stacked enrollment outcomes by module presentation.
3. Top withdrawal-rate module presentations.
4. Engagement by final result.
5. Weekly VLE activity.
6. Assessment score, pass-rate, and late-submission analysis.
7. Demographic withdrawal analysis with precise chart labels.
8. Rule-based risk distribution and observed outcomes.
9. Compact detailed outcomes table.

Global filters are Module and Presentation. Assessment Type, Final Result, and Risk Level are contextual filters mapped only to compatible datasets.

All rates must be recomputed from additive numerators and denominators. Do not average rates, distinct counts, or group medians.

## Data Quality dashboard

Use `data_quality_dashboard.sql` as the formula reference and apply `DATA_QUALITY_DASHBOARD_REVISION_PROMPT.md`.

### DQ Overview

- Weighted DQ Score %, displayed to three decimals
- Check Pass Rate %
- Source Rows Processed
- Failed Rule Evaluations
- Checks Needing Attention
- Six canonical dimensions, including transformation Accuracy
- Current score by validation suite
- Layer and dataset score table
- 100% stacked check-status bar

### Problems & Volume

- Checks Needing Attention drill-down
- Latest source-volume controls
- Checks Needing Attention by Owner

Global filters are Validation Suite, Dataset, Quality Dimension, and Status. Problem-page filters are Severity, Owner, Column, Volume Dataset, and Volume Status.

Do not display a historical trend until at least three run dates exist. Accuracy is cross-layer reconciliation, not external ground truth. The 173 missing score warning is expected and must remain visible.

## Export control

The `.lvdash.json` file is the deployed dashboard definition. Whenever the dashboard is modified in Databricks:

1. Publish and test the dashboard.
2. Export the current `.lvdash.json`.
3. Replace the old repository export.
4. Verify that the export does not contain `Untitled page` or an empty Global Filters page.
5. Confirm every referenced source is created by the full runner.
