-- Databricks notebook source
-- Name: 12 - At-Risk Students
-- Purpose: Create a transparent screening table directly from validated Gold facts.
-- Grain: One student enrollment in one module presentation.
-- Thresholds: 2 points for no VLE use, no submissions, or average score below 40;
--             1 point for fewer than 25 clicks, average score from 40 to below 50,
--             or registration after presentation day zero. High >= 4, Medium >= 2.

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.at_risk_students')
USING DELTA
AS
WITH engagement_signals AS (
  SELECT
    module_presentation_key,
    student_key,
    COUNT(DISTINCT activity_date) AS active_days,
    SUM(sum_click) AS total_clicks
  FROM IDENTIFIER(mart_namespace || '.fact_vle_interaction')
  GROUP BY
    module_presentation_key,
    student_key
),
assessment_signals AS (
  SELECT
    module_presentation_key,
    student_key,
    COUNT(*) AS submission_count,
    AVG(score) AS average_score,
    COUNT_IF(days_from_due_date > 0) AS late_submission_count
  FROM IDENTIFIER(mart_namespace || '.fact_assessment_submission')
  GROUP BY
    module_presentation_key,
    student_key
),
signals AS (
  SELECT
    enrollment.student_enrollment_key,
    enrollment.module_presentation_key,
    enrollment.student_key,
    enrollment.code_module,
    enrollment.code_presentation,
    enrollment.id_student,
    enrollment.date_registration,
    COALESCE(engagement.active_days, 0) AS active_days,
    COALESCE(engagement.total_clicks, 0) AS total_clicks,
    COALESCE(assessment.submission_count, 0) AS submission_count,
    assessment.average_score,
    COALESCE(assessment.late_submission_count, 0) AS late_submission_count,
    enrollment.final_result,
    CASE
      WHEN COALESCE(engagement.total_clicks, 0) = 0 THEN 2
      WHEN engagement.total_clicks < 25 THEN 1
      ELSE 0
    END
      + CASE
        WHEN COALESCE(assessment.submission_count, 0) = 0 THEN 2
        WHEN assessment.average_score < 40 THEN 2
        WHEN assessment.average_score < 50 THEN 1
        ELSE 0
      END
      + CASE WHEN enrollment.date_registration > 0 THEN 1 ELSE 0 END AS risk_score
  FROM IDENTIFIER(mart_namespace || '.fact_student_enrollment') AS enrollment
  LEFT JOIN engagement_signals AS engagement
    ON enrollment.module_presentation_key = engagement.module_presentation_key
    AND enrollment.student_key = engagement.student_key
  LEFT JOIN assessment_signals AS assessment
    ON enrollment.module_presentation_key = assessment.module_presentation_key
    AND enrollment.student_key = assessment.student_key
)
SELECT
  student_enrollment_key,
  module_presentation_key,
  student_key,
  code_module,
  code_presentation,
  id_student,
  date_registration,
  active_days,
  total_clicks,
  submission_count,
  average_score,
  late_submission_count,
  risk_score,
  CASE
    WHEN risk_score >= 4 THEN 'HIGH'
    WHEN risk_score >= 2 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS risk_level,
  final_result
FROM signals;
