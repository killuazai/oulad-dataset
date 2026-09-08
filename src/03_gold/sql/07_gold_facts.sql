-- Databricks notebook source
-- Name: 07 - Gold Facts
-- Purpose: Build enrollment, assessment, and engagement facts with direct conformed-dimension keys.
-- Grain: One student enrollment, one student-assessment submission, or one student-site-day.

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.fact_student_enrollment')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS('||', student.code_module, student.code_presentation, CAST(student.id_student AS STRING)),
    256
  ) AS student_enrollment_key,
  SHA2(CAST(student.id_student AS STRING), 256) AS student_key,
  SHA2(CONCAT_WS('||', student.code_module, student.code_presentation), 256)
    AS module_presentation_key,
  SHA2(
    CONCAT_WS(
      '||', COALESCE(student.gender, 'UNKNOWN'), COALESCE(student.region, 'UNKNOWN'),
      COALESCE(student.highest_education, 'UNKNOWN'), COALESCE(student.imd_band, 'UNKNOWN'),
      COALESCE(student.age_band, 'UNKNOWN'), COALESCE(student.disability, 'UNKNOWN')
    ),
    256
  ) AS demographics_key,
  CASE WHEN registration.date_registration IS NULL THEN NULL
    ELSE SHA2(CAST(registration.date_registration AS STRING), 256) END AS registration_date_key,
  CASE WHEN registration.date_unregistration IS NULL THEN NULL
    ELSE SHA2(CAST(registration.date_unregistration AS STRING), 256) END AS unregistration_date_key,
  student.code_module,
  student.code_presentation,
  student.id_student,
  student.num_of_prev_attempts,
  student.studied_credits,
  registration.date_registration,
  registration.date_unregistration,
  student.final_result,
  CASE WHEN student.final_result = 'Withdrawn' THEN 1 ELSE 0 END AS withdrawn_count,
  CASE WHEN student.final_result = 'Fail' THEN 1 ELSE 0 END AS failed_count,
  CASE WHEN student.final_result = 'Pass' THEN 1 ELSE 0 END AS passed_count,
  CASE WHEN student.final_result = 'Distinction' THEN 1 ELSE 0 END AS distinction_count,
  1 AS enrollment_count
FROM IDENTIFIER(clean_namespace || '.student_info_clean') AS student
LEFT JOIN IDENTIFIER(clean_namespace || '.student_registration_clean') AS registration
  ON student.code_module = registration.code_module
  AND student.code_presentation = registration.code_presentation
  AND student.id_student = registration.id_student;

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.fact_assessment_submission')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS('||', CAST(submission.id_assessment AS STRING), CAST(submission.id_student AS STRING)),
    256
  ) AS assessment_submission_key,
  SHA2(CAST(submission.id_assessment AS STRING), 256) AS assessment_key,
  SHA2(CAST(submission.id_student AS STRING), 256) AS student_key,
  SHA2(CONCAT_WS('||', assessment.code_module, assessment.code_presentation), 256)
    AS module_presentation_key,
  SHA2(
    CONCAT_WS(
      '||', COALESCE(student.gender, 'UNKNOWN'), COALESCE(student.region, 'UNKNOWN'),
      COALESCE(student.highest_education, 'UNKNOWN'), COALESCE(student.imd_band, 'UNKNOWN'),
      COALESCE(student.age_band, 'UNKNOWN'), COALESCE(student.disability, 'UNKNOWN')
    ),
    256
  ) AS demographics_key,
  SHA2(CAST(submission.date_submitted AS STRING), 256) AS submitted_date_key,
  CASE WHEN assessment.assessment_date IS NULL THEN NULL
    ELSE SHA2(CAST(assessment.assessment_date AS STRING), 256) END AS due_date_key,
  assessment.code_module,
  assessment.code_presentation,
  submission.id_assessment,
  submission.id_student,
  submission.date_submitted,
  assessment.assessment_date,
  CASE WHEN assessment.assessment_date IS NULL THEN NULL
    ELSE submission.date_submitted - assessment.assessment_date END AS days_from_due_date,
  submission.is_banked,
  submission.score,
  CASE WHEN submission.score IS NULL THEN NULL
    WHEN submission.score >= 40 THEN TRUE ELSE FALSE END AS passed_assessment,
  1 AS submission_count
FROM IDENTIFIER(clean_namespace || '.student_assessment_clean') AS submission
INNER JOIN IDENTIFIER(clean_namespace || '.assessments_clean') AS assessment
  ON submission.id_assessment = assessment.id_assessment
INNER JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
  ON assessment.code_module = student.code_module
  AND assessment.code_presentation = student.code_presentation
  AND submission.id_student = student.id_student;

CREATE OR REPLACE TABLE IDENTIFIER(mart_namespace || '.fact_vle_interaction')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS(
      '||', interaction.code_module, interaction.code_presentation,
      CAST(interaction.id_student AS STRING), CAST(interaction.id_site AS STRING),
      CAST(interaction.activity_date AS STRING)
    ),
    256
  ) AS vle_interaction_key,
  SHA2(
    CONCAT_WS(
      '||', interaction.code_module, interaction.code_presentation, CAST(interaction.id_site AS STRING)
    ),
    256
  ) AS vle_activity_key,
  SHA2(CAST(interaction.id_student AS STRING), 256) AS student_key,
  SHA2(CONCAT_WS('||', interaction.code_module, interaction.code_presentation), 256)
    AS module_presentation_key,
  SHA2(
    CONCAT_WS(
      '||', COALESCE(student.gender, 'UNKNOWN'), COALESCE(student.region, 'UNKNOWN'),
      COALESCE(student.highest_education, 'UNKNOWN'), COALESCE(student.imd_band, 'UNKNOWN'),
      COALESCE(student.age_band, 'UNKNOWN'), COALESCE(student.disability, 'UNKNOWN')
    ),
    256
  ) AS demographics_key,
  SHA2(CAST(interaction.activity_date AS STRING), 256) AS activity_date_key,
  interaction.code_module,
  interaction.code_presentation,
  interaction.id_student,
  interaction.id_site,
  interaction.activity_date,
  interaction.sum_click,
  1 AS student_site_day_count
FROM IDENTIFIER(clean_namespace || '.student_vle_clean') AS interaction
INNER JOIN IDENTIFIER(clean_namespace || '.student_info_clean') AS student
  ON interaction.code_module = student.code_module
  AND interaction.code_presentation = student.code_presentation
  AND interaction.id_student = student.id_student;
