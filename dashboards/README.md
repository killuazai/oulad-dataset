# Dashboard build guide

Run the full pipeline first. Then create two Databricks Lakeview dashboards from the prepared SQL datasets below. The same queries also work as starting points in Metabase.

## Data quality dashboard

Use `data_quality_dashboard.sql` and place these visuals in reading order:

1. KPI cards: overall score, passed checks, failed checks, critical failures, affected datasets, and last checked time.
2. Horizontal bars: weighted score by quality dimension.
3. Heat map or table: layer and dataset score with PASS, WARNING, and FAIL counts.
4. Problem table: severity, owner, expectation, failed values, and failure rate.
5. Line chart: overall score and failed checks by execution time.
6. Volume chart: observed source row count by dataset and execution time.

The first row should answer pipeline health in about ten seconds. Filters should include `layer`, `dataset_name`, `quality_dimension`, `severity`, `status`, and `executed_at`.

## Business dashboard

Use `business_dashboard.sql` for the Day 7 OULAD questions:

1. Engagement versus final result.
2. Withdrawal patterns by module presentation.
3. VLE activity over relative course week.
4. Outcomes by demographic profile.
5. Late submission rate versus assessment performance.

Keep dashboard joins fact-to-dimension only. Never relate one dimension to another in the BI semantic model; the conformed keys already exist directly on every relevant fact.
