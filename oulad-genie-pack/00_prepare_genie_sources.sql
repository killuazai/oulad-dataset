-- Databricks notebook source
-- Name: 00 - Prepare Genie and Dashboard Sources
-- Purpose: Create governed, dashboard-ready views after the validated pipeline finishes.
-- Prerequisite: Run through tests/13_validate_analytics.sql and the core DQ views first.

-- BUSINESS ANALYTICS

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.genie_outcome_distribution AS
SELECT
  code_module,
  code_presentation,
  final_result,
  COUNT(*) AS student_enrollments
FROM `ftw-week-07`.`04-analytics`.student_cohort
GROUP BY code_module, code_presentation, final_result;

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.genie_engagement_outcomes AS
SELECT
  code_module,
  code_presentation,
  final_result,
  COUNT(*) AS student_enrollments,
  SUM(active_days) AS active_day_sum,
  SUM(activities_used) AS activities_used_sum,
  SUM(total_clicks) AS total_clicks,
  ROUND(AVG(active_days), 2) AS average_active_days,
  ROUND(AVG(activities_used), 2) AS average_activities_used,
  ROUND(AVG(total_clicks), 2) AS average_total_clicks,
  PERCENTILE_APPROX(total_clicks, 0.5) AS median_total_clicks,
  ROUND(AVG(average_clicks_per_active_day), 2) AS average_clicks_per_active_day
FROM `ftw-week-07`.`04-analytics`.student_engagement
GROUP BY code_module, code_presentation, final_result;

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.genie_weekly_activity AS
SELECT
  module.code_module,
  module.code_presentation,
  relative_date.relative_week,
  SUM(interaction.sum_click) AS total_clicks,
  COUNT(DISTINCT interaction.student_key) AS active_students,
  SUM(interaction.student_site_day_count) AS student_site_days,
  COUNT(DISTINCT interaction.id_site) AS activities_used,
  ROUND(
    SUM(interaction.sum_click) / NULLIF(COUNT(DISTINCT interaction.student_key), 0),
    2
  ) AS average_clicks_per_active_student
FROM `ftw-week-07`.`03-mart`.fact_vle_interactions AS interaction
INNER JOIN `ftw-week-07`.`03-mart`.dim_date AS relative_date
  ON interaction.activity_date_key = relative_date.date_key
INNER JOIN `ftw-week-07`.`03-mart`.dim_module_presentation AS module
  ON interaction.module_presentation_key = module.module_presentation_key
GROUP BY module.code_module, module.code_presentation, relative_date.relative_week;

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.genie_demographic_outcomes AS
SELECT
  enrollment.code_module,
  enrollment.code_presentation,
  COALESCE(demographic.gender, 'UNKNOWN') AS gender,
  COALESCE(demographic.age_band, 'UNKNOWN') AS age_band,
  COALESCE(demographic.highest_education, 'UNKNOWN') AS highest_education,
  COALESCE(demographic.imd_band, 'UNKNOWN') AS imd_band,
  COUNT(*) AS student_enrollments,
  SUM(enrollment.withdrawn_count) AS withdrawn_students,
  SUM(enrollment.passed_count + enrollment.distinction_count) AS successful_students,
  ROUND(AVG(enrollment.withdrawn_count), 4) AS withdrawal_rate,
  ROUND(AVG(enrollment.passed_count + enrollment.distinction_count), 4)
    AS successful_outcome_rate,
  ROUND(AVG(enrollment.studied_credits), 2) AS average_studied_credits,
  ROUND(AVG(enrollment.num_of_prev_attempts), 2) AS average_previous_attempts
FROM `ftw-week-07`.`04-analytics`.student_cohort AS enrollment
INNER JOIN `ftw-week-07`.`03-mart`.dim_demographics AS demographic
  ON enrollment.demographics_key = demographic.demographics_key
GROUP BY
  enrollment.code_module,
  enrollment.code_presentation,
  COALESCE(demographic.gender, 'UNKNOWN'),
  COALESCE(demographic.age_band, 'UNKNOWN'),
  COALESCE(demographic.highest_education, 'UNKNOWN'),
  COALESCE(demographic.imd_band, 'UNKNOWN');

CREATE OR REPLACE VIEW `ftw-week-07`.`04-analytics`.genie_risk_summary AS
SELECT
  code_module,
  code_presentation,
  risk_level,
  CASE risk_level WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END
    AS risk_level_order,
  COUNT(*) AS student_enrollments,
  COUNT_IF(final_result = 'Withdrawn') AS withdrawn_students,
  COUNT_IF(final_result IN ('Pass', 'Distinction')) AS successful_students,
  ROUND(AVG(risk_score), 2) AS average_risk_score,
  ROUND(AVG(active_days), 2) AS average_active_days,
  ROUND(AVG(total_clicks), 2) AS average_total_clicks,
  ROUND(AVG(average_score), 2) AS average_assessment_score,
  ROUND(AVG(CASE WHEN final_result = 'Withdrawn' THEN 1 ELSE 0 END), 4)
    AS observed_withdrawal_rate
FROM `ftw-week-07`.`04-analytics`.at_risk_students
GROUP BY code_module, code_presentation, risk_level;

-- DATA QUALITY

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_latest_check_results AS
SELECT
  run_id, executed_at, layer, dataset_name, column_name, check_name,
  quality_dimension, check_type, expectation, threshold_pct, severity,
  check_owner, total_count, failed_count, passed_count, score_pct,
  failure_pct, status
FROM `ftw-week-07`.`05-data-quality`.dq_latest_check_results;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_dq_overview AS
SELECT
  overview.last_checked_at,
  overview.total_checks,
  overview.passed_checks,
  overview.warning_checks,
  overview.failed_checks,
  overview.critical_failures,
  overview.checks_needing_attention,
  overview.validation_suites_checked AS layers_checked,
  overview.datasets_checked,
  volume.source_rows_processed,
  totals.evaluated_values,
  overview.failed_rule_evaluations,
  overview.check_pass_rate_pct,
  overview.weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_overview AS overview
CROSS JOIN (
  SELECT SUM(total_count) AS source_rows_processed
  FROM `ftw-week-07`.`05-data-quality`.dq_latest_check_results
  WHERE layer = 'BRONZE' AND check_type = 'VOLUME'
) AS volume
CROSS JOIN (
  SELECT SUM(total_count) AS evaluated_values
  FROM `ftw-week-07`.`05-data-quality`.dq_latest_check_results
) AS totals;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_dq_canonical_dimensions AS
SELECT
  dimension_order, dimension_key, dimension_label, total_checks, passed_checks,
  warning_checks, failed_checks, failed_rule_evaluations,
  weighted_quality_score_pct, measurement_status, measurement_note
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_canonical_dimensions;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_dq_dimension_scores AS
SELECT
  quality_dimension, total_checks, passed_checks, warning_checks, failed_checks,
  failed_rule_evaluations, weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_dimension_scores;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_dq_dataset_scores AS
SELECT
  layer, dataset_name, total_checks, passed_checks, warning_checks, failed_checks,
  failed_rule_evaluations, weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_dataset_scores;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_dq_problem_areas AS
SELECT
  executed_at, layer, dataset_name, column_name, check_name, quality_dimension,
  check_type, expectation, threshold_pct, severity, check_owner, total_count,
  failed_count, failure_pct, status
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_problem_areas;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_dq_layer_history AS
SELECT
  run_id,
  executed_at,
  layer,
  COUNT(*) AS total_checks,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  SUM(failed_count) AS failed_rule_evaluations,
  ROUND(100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0), 3)
    AS weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.dq_check_results
GROUP BY run_id, executed_at, layer;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_dq_daily_history AS
SELECT
  run_date, total_checks, passed_checks, warning_checks, failed_checks,
  failed_rule_evaluations, weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_daily_history;

CREATE OR REPLACE VIEW `ftw-week-07`.`05-data-quality`.genie_dq_volume_history AS
SELECT
  run_id,
  executed_at,
  layer,
  dataset_name,
  check_name,
  expectation,
  observed_row_count,
  difference_from_baseline AS failed_count,
  status
FROM `ftw-week-07`.`05-data-quality`.dq_dashboard_volume_history;
