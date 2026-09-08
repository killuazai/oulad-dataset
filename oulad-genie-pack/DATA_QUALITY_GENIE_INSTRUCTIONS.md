# OULAD Data Quality Genie

## Suggested space description

Explains the current and historical health of the OULAD Bronze, Silver, Gold, and Analytics layers, including quality dimensions, datasets, warnings, failures, ownership, thresholds, and source-volume checks.

## Add these data objects

- `ftw-week-07.05-data-quality.genie_dq_overview`
- `ftw-week-07.05-data-quality.genie_dq_canonical_dimensions`
- `ftw-week-07.05-data-quality.genie_dq_dimension_scores`
- `ftw-week-07.05-data-quality.genie_dq_dataset_scores`
- `ftw-week-07.05-data-quality.genie_dq_problem_areas`
- `ftw-week-07.05-data-quality.genie_dq_layer_history`
- `ftw-week-07.05-data-quality.genie_dq_daily_history`
- `ftw-week-07.05-data-quality.genie_dq_volume_history`

Do not add `dq_check_results` to the space. The governed Genie views already expose the necessary results at safer grains.

## General instructions to paste into Genie

Use only the governed data-quality views included in this space. Do not query business facts or infer learner outcomes from data-quality results.

For “current,” “latest,” or “now,” use the overview, dimension, dataset, or problem-area views. They contain the latest completed validator run for each pipeline layer.

`PASS` means the configured expectation was met. `WARNING` means the result needs review but does not fail the pipeline. `FAIL` means the expectation failed. Do not call warnings failures.

`weighted_quality_score_pct` is 100 multiplied by total passed rule evaluations divided by total evaluated values. It is not the percentage of checks that passed.

For the six reference dashboard dimensions, use `genie_dq_canonical_dimensions`. If `measurement_status = 'NOT_MEASURED'`, report the value as N/A and explain the measurement note. Never convert a missing dimension to 0%. Accuracy is currently not measured because no authoritative reference comparison exists.

`failed_rule_evaluations` and sums of `failed_count` are rule failures, not necessarily distinct source rows. The same source row may violate more than one check. Use “rule evaluations” or “affected values,” not “unique bad rows.”

Always state the layer, dataset, check name, status, severity, expectation, failed count, failure percentage, and owner when explaining a problem when those fields are available.

Use `genie_dq_daily_history` for the overall dashboard trend. Use `genie_dq_layer_history` for layer-specific trends. Its grain is one validation run per layer; do not present separate layer run IDs as one shared pipeline run.

Use `genie_dq_volume_history` only for volume questions. `observed_row_count` is the row count recorded by that volume check.

A critical failure means `status = 'FAIL' AND severity = 'CRITICAL'`. Do not infer criticality from the failed count alone.

Present fields ending in `_pct` with a percent sign. Sort problems with failures before warnings, then critical severity first, then the largest failed count.

## Recommended sample questions

1. What is the current overall data quality status?
2. Which current data quality checks need attention?
3. What is the current data quality score for each layer and dataset?
4. Which data quality dimensions have the lowest scores?
5. Which owners have unresolved data quality issues?
6. How has data quality changed over time for each layer?
7. Show source volume history and any failed volume checks.
8. Are there any current critical data quality failures?

Use the matching question/SQL pairs in `02_data_quality_examples.sql` as Genie SQL examples.
