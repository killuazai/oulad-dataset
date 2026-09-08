# OULAD Data Quality Dashboard Layout

The supplied screenshot is the visual reference. Use its clean KPI-first hierarchy, but populate every visual from the governed views rather than entering sample numbers manually.

## Recommended canvas

### Row 1 — Executive KPI cards

Use Dataset 1 from `03_data_quality_dashboard.sql`.

1. **DQ score** — `dq_score_pct`, percentage with one decimal.
2. **Source rows processed** — `source_rows_processed`, integer with thousands separators.
3. **Failed rule evaluations** — `failed_rule_evaluations`, integer with thousands separators.
4. **Checks needing attention** — `checks_needing_attention`, integer.

Do not label `failed_rule_evaluations` as “failed rows.” One row can fail multiple rules, so that label would overstate the number of unique bad records.

### Row 2 — Quality dimensions

Use Dataset 2. Create six gauge or donut tiles, filtered by `dimension_label`:

1. Completeness
2. Timeliness / Volume
3. Validity
4. Accuracy
5. Consistency
6. Uniqueness

Display `weighted_quality_score_pct` in the center. When `measurement_status = 'NOT_MEASURED'`, show **N/A — Not measured**, not 0%. Accuracy currently needs an authoritative reference dataset before it can receive a defensible score. Consistency includes referential-integrity checks.

Suggested color rules:

- Green: score at least 99% and no failed checks.
- Amber: warning exists or score is from 95% to below 99%.
- Red: failed check exists or score is below 95%.
- Gray: not measured.

These colors are display rules, not replacements for each check's configured threshold.

### Row 3 — Quality trend

Use Dataset 3 as a line chart:

- X-axis: `run_date`
- Y-axis: `dq_score_pct`
- Tooltip: total, warning, and failed checks
- Title: **Overall DQ score — last 12 months**

The chart will initially have only one point if the pipeline has run on only one date. History accumulates automatically as validation results are appended.

### Row 4 — Operational health

- Dataset 4: stacked bar or donut for PASS, WARNING, and FAIL check counts.
- Dataset 5: heatmap or table with `layer`, `dataset_name`, and `weighted_quality_score_pct`.
- Recommended filters: layer, dataset, status, severity, quality dimension, and execution date.

### Row 5 — Action and ownership

- Dataset 6: issue drill-down table. Apply red styling to FAIL and amber styling to WARNING.
- Dataset 7: bar chart of unresolved checks by owner.
- Dataset 8: source-volume trend by dataset.

## Dashboard title and subtitle

**Title:** OULAD Data Quality Monitoring

**Subtitle:** Latest Bronze, Silver, Gold, and Analytics validation results with historical trends and accountable issue ownership.

## Important interpretation rules

- The DQ score is weighted by evaluated values, not simply the percentage of checks that passed.
- Warnings need review but do not mean the pipeline failed.
- Accuracy is intentionally not scored until a trusted external reference or reconciliation rule exists.
- Source rows processed comes from the latest Bronze volume checks and does not sum the same records again across downstream layers.
- The current snapshot uses the latest completed validation run separately for each layer because the existing validators create separate run IDs.

