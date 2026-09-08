-- Databricks notebook source
-- OULAD Business Analytics dashboard datasets.
-- Rates are reconstructed from additive numerators and denominators.

-- Dataset 1: Outcome KPI cards
SELECT
  SUM(enrolled_students) AS total_enrollments,
  SUM(passed_students + distinction_students) AS successful_students,
  ROUND(
    100.0 * SUM(passed_students + distinction_students)
      / NULLIF(SUM(enrolled_students), 0),
    2
  ) AS successful_outcome_rate_pct,
  ROUND(
    100.0 * SUM(withdrawn_students) / NULLIF(SUM(enrolled_students), 0),
    2
  ) AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.learner_outcomes;

-- COMMAND ----------

-- Dataset 2: Assessment KPI cards; do not average pre-aggregated rates.
SELECT
  SUM(submission_count) AS submissions,
  SUM(scored_submission_count) AS scored_submissions,
  SUM(missing_score_count) AS missing_scores,
  ROUND(
    SUM(score_sum) / NULLIF(SUM(scored_submission_count), 0),
    2
  ) AS average_assessment_score,
  ROUND(
    100.0 * SUM(passed_submission_count)
      / NULLIF(SUM(scored_submission_count), 0),
    2
  ) AS assessment_pass_rate_pct,
  ROUND(
    100.0 * SUM(late_submission_count)
      / NULLIF(SUM(dated_submission_count), 0),
    2
  ) AS late_submission_rate_pct
FROM `ftw-week-07`.`04-analytics`.assessment_performance;

-- COMMAND ----------

-- Dataset 3: Stacked outcome distribution by module presentation
SELECT
  code_module,
  code_presentation,
  CONCAT(code_module, ' - ', code_presentation) AS module_presentation,
  final_result,
  student_enrollments
FROM `ftw-week-07`.`04-analytics`.genie_outcome_distribution
ORDER BY code_module, code_presentation, final_result;

-- COMMAND ----------

-- Dataset 4: Highest withdrawal-rate module presentations
SELECT
  code_module,
  code_presentation,
  CONCAT(code_module, ' - ', code_presentation) AS module_presentation,
  enrolled_students,
  withdrawn_students,
  ROUND(100.0 * withdrawal_rate, 2) AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.learner_outcomes
ORDER BY withdrawal_rate DESC, enrolled_students DESC
LIMIT 10;

-- COMMAND ----------

-- Dataset 5: Engagement by outcome
SELECT
  final_result,
  SUM(student_enrollments) AS student_enrollments,
  ROUND(
    SUM(active_day_sum) / NULLIF(SUM(student_enrollments), 0),
    2
  ) AS average_active_days,
  ROUND(
    SUM(total_clicks) / NULLIF(SUM(student_enrollments), 0),
    2
  ) AS average_total_clicks
FROM `ftw-week-07`.`04-analytics`.genie_engagement_outcomes
GROUP BY final_result
ORDER BY average_total_clicks DESC;

-- COMMAND ----------

-- Dataset 6: Weekly activity; negative weeks correctly represent pre-presentation activity.
SELECT
  code_module,
  code_presentation,
  relative_week,
  total_clicks,
  active_students,
  average_clicks_per_active_student
FROM `ftw-week-07`.`04-analytics`.genie_weekly_activity
ORDER BY code_module, code_presentation, relative_week;

-- COMMAND ----------

-- Dataset 7: Assessment performance by module and type
SELECT
  code_module,
  code_presentation,
  assessment_type,
  SUM(submission_count) AS submissions,
  ROUND(SUM(score_sum) / NULLIF(SUM(scored_submission_count), 0), 2)
    AS average_score,
  ROUND(
    100.0 * SUM(passed_submission_count)
      / NULLIF(SUM(scored_submission_count), 0),
    2
  ) AS pass_rate_pct,
  ROUND(
    100.0 * SUM(late_submission_count)
      / NULLIF(SUM(dated_submission_count), 0),
    2
  ) AS late_submission_rate_pct
FROM `ftw-week-07`.`04-analytics`.assessment_performance
GROUP BY code_module, code_presentation, assessment_type
ORDER BY code_module, code_presentation, assessment_type;

-- COMMAND ----------

-- Dataset 8: Demographic withdrawal rates; use one selected dimension at a time in BI.
SELECT
  gender,
  age_band,
  highest_education,
  imd_band,
  SUM(student_enrollments) AS student_enrollments,
  SUM(withdrawn_students) AS withdrawn_students,
  ROUND(
    100.0 * SUM(withdrawn_students) / NULLIF(SUM(student_enrollments), 0),
    2
  ) AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.genie_demographic_outcomes
GROUP BY gender, age_band, highest_education, imd_band;

-- COMMAND ----------

-- Dataset 9: Risk distribution by module presentation
SELECT
  code_module,
  code_presentation,
  CONCAT(code_module, ' - ', code_presentation) AS module_presentation,
  risk_level,
  risk_level_order,
  student_enrollments
FROM `ftw-week-07`.`04-analytics`.genie_risk_summary
ORDER BY code_module, code_presentation, risk_level_order;

-- COMMAND ----------

-- Dataset 10: Observed outcomes by rule-based risk level
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
