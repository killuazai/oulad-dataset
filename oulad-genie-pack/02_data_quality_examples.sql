-- Verified-style examples for the Data Quality Genie space.

-- Question: What is the current overall data-quality status?
SELECT
  last_checked_at,
  total_checks,
  passed_checks,
  warning_checks,
  failed_checks,
  checks_needing_attention,
  layers_checked AS validation_suites_checked,
  weighted_quality_score_pct,
  check_pass_rate_pct
FROM `ftw-week-07`.`05-data-quality`.genie_dq_overview;

-- Question: Are all six quality dimensions measured?
SELECT
  dimension_order,
  dimension_label,
  measurement_status,
  weighted_quality_score_pct,
  measurement_note
FROM `ftw-week-07`.`05-data-quality`.genie_dq_canonical_dimensions
ORDER BY dimension_order;

-- Question: Which current checks need attention?
SELECT
  status,
  severity,
  layer AS validation_suite,
  dataset_name,
  column_name,
  check_name,
  quality_dimension,
  failed_count,
  failure_pct,
  expectation,
  check_owner
FROM `ftw-week-07`.`05-data-quality`.genie_dq_problem_areas
ORDER BY
  CASE status WHEN 'FAIL' THEN 1 ELSE 2 END,
  CASE severity WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 ELSE 4 END,
  failed_count DESC;

-- Question: What is the current score for each validation suite?
SELECT
  layer AS validation_suite,
  COUNT(*) AS total_checks,
  COUNT_IF(status = 'PASS') AS passed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  ROUND(100.0 * SUM(passed_count) / NULLIF(SUM(total_count), 0), 3)
    AS weighted_quality_score_pct
FROM `ftw-week-07`.`05-data-quality`.genie_latest_check_results
GROUP BY layer
ORDER BY layer;

-- Question: Which owners have checks needing attention?
SELECT
  check_owner,
  COUNT(*) AS checks_needing_attention,
  COUNT_IF(status = 'FAIL') AS failed_checks,
  COUNT_IF(status = 'WARNING') AS warning_checks,
  SUM(failed_count) AS failed_rule_evaluations
FROM `ftw-week-07`.`05-data-quality`.genie_dq_problem_areas
GROUP BY check_owner
ORDER BY failed_checks DESC, warning_checks DESC;
