# Prompt for the Databricks dashboard assistant

Review the current OULAD Business Analytics dashboard and apply all changes below. Do not invent columns, measures, or datasets. Preserve the dashboard until the complete revision is ready, then apply it as one coherent update.

Use only these governed sources in `ftw-week-07.04-analytics`:

- `learner_outcomes`
- `assessment_performance`
- `genie_outcome_distribution`
- `genie_engagement_outcomes`
- `genie_weekly_activity`
- `genie_demographic_outcomes`
- `genie_risk_summary`

Rename the main page from `Untitled page` to `Business Analytics Overview`.

Add dashboard filters:

- Global across compatible datasets: `code_module`, `code_presentation`.
- Contextual filters for relevant visuals: `assessment_type`, `final_result`, `risk_level`.
- An empty selection must mean All.
- Do not map a filter to a dataset that does not contain its field.

Correct the Assessment Performance metric definitions:

```text
submissions = SUM(submission_count)
scored_submissions = SUM(scored_submission_count)
missing_scores = SUM(missing_score_count)
average_assessment_score = SUM(score_sum) / NULLIF(SUM(scored_submission_count), 0)
assessment_pass_rate_pct = 100 * SUM(passed_submission_count) / NULLIF(SUM(scored_submission_count), 0)
late_submission_rate_pct = 100 * SUM(late_submission_count) / NULLIF(SUM(dated_submission_count), 0)
```

Never weight pass rate or late-submission rate by `submission_count`. Do not sum `submitting_students` outside its module-presentation and assessment-type grain. Do not average or weight group medians and call the result an overall median.

Create this layout:

1. KPI cards: Total Enrollments, Successful Outcome Rate, Withdrawal Rate, Average Assessment Score, Assessment Pass Rate, Late Submission Rate.
2. A stacked bar named `Enrollment Outcomes by Module Presentation`, using `genie_outcome_distribution`: category `module_presentation`, stack/color `final_result`, value `SUM(student_enrollments)`.
3. A horizontal bar named `Top 10 Module Presentations by Withdrawal Rate`, sorted descending. Include enrollment count in the tooltip.
4. A clustered bar named `Engagement by Final Result`, showing average active days and average total clicks. Compute averages from additive sums divided by enrollments.
5. A line chart named `Weekly VLE Activity`, x-axis `relative_week`, y-axis `SUM(total_clicks)`, color by module presentation. Negative weeks mean pre-presentation activity and must not be removed by default.
6. A combined or grouped chart named `Assessment Performance by Type`, showing average score and pass-rate percentage.
7. A horizontal bar named `Late Submission Rate by Module and Assessment Type`, using the correct dated-submission denominator.
8. A horizontal bar named `Withdrawal Rate by Age Band`. Rename it precisely; do not call an age-only chart “by Demographics.”
9. A stacked bar named `Risk Distribution by Module Presentation`, category module presentation, stack/color risk level, value enrollments.
10. A bar named `Observed Withdrawal Rate by Rule-Based Risk Level`. State in the subtitle that risk is a transparent screening rule and not a predictive model.
11. Retain a compact detailed outcomes table.

Format percentages with two decimals and counts with thousands separators. Use consistent outcome colors and risk colors. Remove any empty page. After applying the changes, summarize the final datasets, filters, formulas, and widgets for review before publishing.
