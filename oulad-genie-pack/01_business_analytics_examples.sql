-- Verified-style examples for the Business Analytics Genie space.

-- Question: Which module presentations have the highest withdrawal rate?
SELECT
  code_module,
  code_presentation,
  enrolled_students,
  withdrawn_students,
  ROUND(100.0 * withdrawn_students / NULLIF(enrolled_students, 0), 2)
    AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.learner_outcomes
ORDER BY withdrawal_rate_pct DESC, enrolled_students DESC;

-- Question: How does engagement differ by final result?
SELECT
  final_result,
  SUM(student_enrollments) AS student_enrollments,
  ROUND(SUM(active_day_sum) / NULLIF(SUM(student_enrollments), 0), 2)
    AS average_active_days,
  ROUND(SUM(total_clicks) / NULLIF(SUM(student_enrollments), 0), 2)
    AS average_total_clicks
FROM `ftw-week-07`.`04-analytics`.genie_engagement_outcomes
GROUP BY final_result
ORDER BY average_total_clicks DESC;

-- Question: Compare assessment performance by assessment type.
SELECT
  assessment_type,
  SUM(submission_count) AS submissions,
  ROUND(SUM(score_sum) / NULLIF(SUM(scored_submission_count), 0), 2)
    AS average_score,
  ROUND(
    100.0 * SUM(passed_submission_count) / NULLIF(SUM(scored_submission_count), 0),
    2
  ) AS pass_rate_pct,
  ROUND(
    100.0 * SUM(late_submission_count) / NULLIF(SUM(dated_submission_count), 0),
    2
  ) AS late_submission_rate_pct
FROM `ftw-week-07`.`04-analytics`.assessment_performance
GROUP BY assessment_type
ORDER BY assessment_type;

-- Question: Show weekly engagement for each module presentation.
SELECT
  code_module,
  code_presentation,
  relative_week,
  total_clicks,
  active_students,
  average_clicks_per_active_student
FROM `ftw-week-07`.`04-analytics`.genie_weekly_activity
ORDER BY code_module, code_presentation, relative_week;

-- Question: Which age bands have the highest withdrawal rate?
SELECT
  age_band,
  SUM(student_enrollments) AS student_enrollments,
  SUM(withdrawn_students) AS withdrawn_students,
  ROUND(
    100.0 * SUM(withdrawn_students) / NULLIF(SUM(student_enrollments), 0),
    2
  ) AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.genie_demographic_outcomes
GROUP BY age_band
HAVING SUM(student_enrollments) >= 20
ORDER BY withdrawal_rate_pct DESC;

-- Question: Does rule-based risk align with observed withdrawal rates?
SELECT
  risk_level,
  MIN(risk_level_order) AS risk_level_order,
  SUM(student_enrollments) AS student_enrollments,
  SUM(withdrawn_students) AS withdrawn_students,
  ROUND(
    100.0 * SUM(withdrawn_students) / NULLIF(SUM(student_enrollments), 0),
    2
  ) AS observed_withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.genie_risk_summary
GROUP BY risk_level
ORDER BY risk_level_order;
