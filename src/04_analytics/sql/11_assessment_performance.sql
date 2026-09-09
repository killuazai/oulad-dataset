-- Databricks notebook source
-- Name: 11 - Assessment Performance
-- Purpose: Publish additive assessment controls and descriptive metrics.
-- Grain: One module presentation and assessment type.

DECLARE OR REPLACE VARIABLE analytics_namespace STRING DEFAULT '`ftw-week-07`.`04-analytics`';
DECLARE OR REPLACE VARIABLE mart_namespace STRING DEFAULT '`ftw-week-07`.`03-mart`';

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.assessment_performance')
USING DELTA
AS
SELECT
  module_presentation_key,
  course_key,
  code_module,
  code_presentation,
  assessment_type,
  COUNT(*) AS submission_count,
  COUNT(DISTINCT student_key) AS submitting_students,
  COUNT_IF(score IS NOT NULL) AS scored_submission_count,
  COUNT_IF(score IS NULL) AS missing_score_count,
  SUM(COALESCE(score, 0)) AS score_sum,
  COUNT_IF(score IS NOT NULL AND passed_assessment) AS passed_submission_count,
  COUNT_IF(due_relative_day IS NOT NULL) AS dated_submission_count,
  COUNT_IF(due_relative_day IS NOT NULL AND days_from_due_date > 0) AS late_submission_count,
  AVG(score) AS average_score,
  PERCENTILE_APPROX(score, 0.5) AS median_score,
  1.0 * COUNT_IF(score IS NOT NULL AND passed_assessment)
    / NULLIF(COUNT_IF(score IS NOT NULL), 0) AS pass_rate,
  1.0 * COUNT_IF(due_relative_day IS NOT NULL AND days_from_due_date > 0)
    / NULLIF(COUNT_IF(due_relative_day IS NOT NULL), 0) AS late_submission_rate
FROM IDENTIFIER(mart_namespace || '.fact_assessments')
GROUP BY module_presentation_key, course_key, code_module, code_presentation, assessment_type;
