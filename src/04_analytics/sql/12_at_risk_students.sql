-- Databricks notebook source
-- Name: 12 - At-Risk Students
-- Purpose: Create a transparent screening table from the two validated core facts.
-- Grain: One student in one module presentation.

DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.at_risk_students')
USING DELTA
AS
WITH engagement_signals AS (
  SELECT
    module_presentation_key,
    student_key,
    COUNT(DISTINCT activity_relative_day) AS active_days,
    SUM(sum_click) AS total_clicks
  FROM IDENTIFIER(mart_namespace || '.fact_vle_interactions')
  GROUP BY module_presentation_key, student_key
),
assessment_signals AS (
  SELECT
    module_presentation_key,
    student_key,
    COUNT(*) AS submission_count,
    AVG(score) AS average_score,
    COUNT_IF(days_from_due_date > 0) AS late_submission_count
  FROM IDENTIFIER(mart_namespace || '.fact_assessments')
  GROUP BY module_presentation_key, student_key
),
signals AS (
  SELECT
    cohort.student_cohort_key,
    cohort.module_presentation_key,
    cohort.course_key,
    cohort.student_key,
    cohort.demographics_key,
    cohort.code_module,
    cohort.code_presentation,
    cohort.id_student,
    cohort.date_registration,
    COALESCE(engagement.active_days, 0) AS active_days,
    COALESCE(engagement.total_clicks, 0) AS total_clicks,
    COALESCE(assessment.submission_count, 0) AS submission_count,
    assessment.average_score,
    COALESCE(assessment.late_submission_count, 0) AS late_submission_count,
    cohort.final_result,
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
      + CASE WHEN cohort.date_registration > 0 THEN 1 ELSE 0 END AS risk_score
  FROM IDENTIFIER(analytics_namespace || '.student_cohort') AS cohort
  LEFT JOIN engagement_signals AS engagement
    ON cohort.module_presentation_key = engagement.module_presentation_key
    AND cohort.student_key = engagement.student_key
  LEFT JOIN assessment_signals AS assessment
    ON cohort.module_presentation_key = assessment.module_presentation_key
    AND cohort.student_key = assessment.student_key
)
SELECT
  student_cohort_key,
  module_presentation_key,
  course_key,
  student_key,
  demographics_key,
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
