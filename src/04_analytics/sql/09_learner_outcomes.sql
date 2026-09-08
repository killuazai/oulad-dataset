-- Databricks notebook source
-- Name: 09 - Learner Outcomes
-- Purpose: Summarize enrollment and completion outcomes by course presentation.
-- Grain: One row per course presentation.

CREATE OR REPLACE TABLE IDENTIFIER(analytics_namespace || '.learner_outcomes')
USING DELTA
AS
SELECT
  module_presentation_key,
  code_module,
  code_presentation,
  COUNT(*) AS enrolled_students,
  COUNT_IF(final_result = 'Withdrawn') AS withdrawn_students,
  COUNT_IF(final_result = 'Fail') AS failed_students,
  COUNT_IF(final_result = 'Pass') AS passed_students,
  COUNT_IF(final_result = 'Distinction') AS distinction_students,
  AVG(CASE WHEN final_result IN ('Pass', 'Distinction') THEN 1.0 ELSE 0.0 END) AS successful_outcome_rate,
  AVG(CASE WHEN final_result = 'Withdrawn' THEN 1.0 ELSE 0.0 END) AS withdrawal_rate,
  AVG(studied_credits) AS average_studied_credits,
  AVG(num_of_prev_attempts) AS average_previous_attempts
FROM IDENTIFIER(mart_namespace || '.fact_student_enrollment')
GROUP BY
  module_presentation_key,
  code_module,
  code_presentation;
