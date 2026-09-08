# OULAD Business Analytics Genie instructions

Use only governed objects in `ftw-week-07.04-analytics`:

- `learner_outcomes`
- `assessment_performance`
- `genie_outcome_distribution`
- `genie_engagement_outcomes`
- `genie_weekly_activity`
- `genie_demographic_outcomes`
- `genie_risk_summary`

Always state the module/presentation filters and the grain of the answer.

Outcome definitions:

- Successful = Pass or Distinction.
- Withdrawal rate = withdrawn enrollments / enrollments.
- A learner can occur in more than one module presentation; describe counts as enrollments unless a distinct learner count is explicitly computed.

Assessment formulas:

- Average score = `SUM(score_sum) / SUM(scored_submission_count)`.
- Pass rate = `SUM(passed_submission_count) / SUM(scored_submission_count)`.
- Late-submission rate = `SUM(late_submission_count) / SUM(dated_submission_count)`.
- Missing scores remain excluded from score and pass-rate denominators.
- Exams without a due date remain excluded from the late-rate denominator.

Do not average pre-aggregated rates. Do not sum `submitting_students` across assessment groups. Do not average group medians and present the result as an overall median.

Risk is a transparent coursework screening rule, not a trained predictive model. Refer to its withdrawal rate as observed withdrawal rate, not prediction accuracy.

OULAD activity dates and weeks are relative to presentation start. Negative values mean pre-presentation activity and are valid.
