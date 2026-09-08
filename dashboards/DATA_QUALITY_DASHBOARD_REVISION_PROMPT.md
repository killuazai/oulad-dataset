# Prompt for the Databricks dashboard assistant

Review the current OULAD Data Quality Monitoring dashboard and apply all changes below. Use only governed `genie_*` views in `ftw-week-07.05-data-quality`. Do not invent results or convert missing measurements to zero.

Global filters:

- Validation Suite (`layer`)
- Dataset (`dataset_name`)
- Quality Dimension (`quality_dimension`)
- Status (`status`)

Keep page-specific filters on Problems & Volume for Severity, Check Owner, Column Name, Volume Dataset, and Volume Status. Empty selection means All.

DQ Overview page:

1. Rename `DQ Score` to `Weighted DQ Score %` and display three decimal places. Its formula is `100 * SUM(passed_count) / SUM(total_count)`.
2. Add or retain `Check Pass Rate %`, with formula `100 * passed checks / total checks`, because a weighted score can round to 100 while a warning still exists.
3. Retain Source Rows Processed, Failed Rule Evaluations, and Checks Needing Attention.
4. Display all six canonical dimensions in fixed order: Completeness, Timeliness / Volume, Validity, Accuracy, Consistency, Uniqueness.
5. Accuracy uses `dimension_key = 'ACCURACY'`. It is measured by reconciliation rules inside Analytics validation. Its tooltip/subtitle must say: `Cross-layer transformation reconciliation; not external ground truth.` If it has not run, show N/A rather than zero.
6. Rename the suite chart to `Current Quality Score by Validation Suite`. It must show BRONZE, SILVER, GOLD, and ANALYTICS after a complete run. Accuracy is a dimension inside ANALYTICS, not a fifth suite.
7. Retain the Layer & Dataset Quality Scores table and the 100% stacked Check Status Breakdown.
8. Do not display a time-series chart until `genie_dq_daily_history` contains at least three distinct run dates. When it becomes meaningful, use a compact trend chart rather than a large empty panel.
9. Replace the subtitle with: `Latest completed result for each validation suite, with weighted scores, issue ownership, and source-volume controls.`

Problems & Volume page:

1. Retain Checks Needing Attention as the main drill-down table.
2. Retain Source Volume by Dataset as a compact ranked table.
3. Retain Checks Needing Attention by Owner as a compact summary table.
4. The 173 missing assessment scores must remain one MEDIUM-severity WARNING under owner `analytics`; do not relabel it PASS and do not impute the scores.

Use consistent semantic colors: PASS green, WARNING amber, FAIL red, NOT_MEASURED gray. Format percentages to three decimals for DQ scores and failure rates. After applying changes, summarize the final datasets, filters, formulas, and widgets before publishing.
