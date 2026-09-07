-- Databricks notebook source
-- Name: 13 - Analytics Validation
-- Purpose: Stop the pipeline when analytical outputs are empty, duplicated, or out of bounds.
-- Grain: One row per named quality check.

WITH checks AS (
  SELECT
    'learner outcomes are populated, unique, and bounded' AS check_name,
    COUNT_IF(
      course_presentation_key IS NULL
      OR successful_outcome_rate NOT BETWEEN 0 AND 1
      OR withdrawal_rate NOT BETWEEN 0 AND 1
      OR enrolled_students <= 0
    )
      + COUNT(*)
      - COUNT(DISTINCT course_presentation_key)
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END AS failed_rows
  FROM IDENTIFIER(oulad_catalog || '.oulad_analytics.learner_outcomes')

  UNION ALL

  SELECT
    'student engagement reconciles with student-course fact',
    COUNT_IF(
      student_course_key IS NULL
      OR active_days < 0
      OR activities_used < 0
      OR total_clicks < 0
    )
      + COUNT(*)
      - COUNT(DISTINCT student_course_key)
      + ABS(
        COUNT(*)
        - (SELECT COUNT(*) FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_student_course'))
      )
  FROM IDENTIFIER(oulad_catalog || '.oulad_analytics.student_engagement')

  UNION ALL

  SELECT
    'assessment performance is populated and bounded',
    COUNT_IF(
      submission_count <= 0
      OR average_score IS NULL
      OR average_score NOT BETWEEN 0 AND 100
      OR pass_rate IS NULL
      OR pass_rate NOT BETWEEN 0 AND 1
      OR late_submission_rate NOT BETWEEN 0 AND 1
    )
      + COUNT(*)
      - COUNT(DISTINCT STRUCT(course_presentation_key, assessment_type))
      + CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
  FROM IDENTIFIER(oulad_catalog || '.oulad_analytics.assessment_performance')

  UNION ALL

  SELECT
    'at-risk rows reconcile with student-course fact',
    COUNT_IF(
      student_course_key IS NULL
      OR risk_score < 0
      OR risk_score > 5
      OR risk_level NOT IN ('LOW', 'MEDIUM', 'HIGH')
    )
      + COUNT(*)
      - COUNT(DISTINCT student_course_key)
      + ABS(
        COUNT(*)
        - (SELECT COUNT(*) FROM IDENTIFIER(oulad_catalog || '.oulad_gold.fact_student_course'))
      )
  FROM IDENTIFIER(oulad_catalog || '.oulad_analytics.at_risk_students')
)
SELECT
  check_name,
  failed_rows,
  CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
  ASSERT_TRUE(
    SUM(failed_rows) OVER () = 0,
    'one or more Analytics checks failed; review the named checks'
  ) AS analytics_validation_check
FROM checks
ORDER BY check_name;
