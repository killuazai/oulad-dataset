-- Databricks notebook source
-- Name: 04 - Silver Tables
-- Purpose: Clean source rows, normalize domains, and retain only conformed relationships.
-- Grain: One clean row at the original grain of each source entity or event.

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean')
USING DELTA
AS
SELECT
  UPPER(TRIM(code_module)) AS code_module,
  UPPER(TRIM(code_presentation)) AS code_presentation,
  module_presentation_length
FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.courses')
WHERE code_module IS NOT NULL
  AND TRIM(code_module) <> ''
  AND code_presentation IS NOT NULL
  AND TRIM(code_presentation) <> ''
  AND module_presentation_length > 0;

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_silver.assessments_clean')
USING DELTA
AS
SELECT
  assessment.id_assessment,
  UPPER(TRIM(assessment.code_module)) AS code_module,
  UPPER(TRIM(assessment.code_presentation)) AS code_presentation,
  assessment.assessment_type,
  assessment.assessment_date,
  assessment.weight
FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.assessments') AS assessment
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean') AS course
  ON UPPER(TRIM(assessment.code_module)) = course.code_module
  AND UPPER(TRIM(assessment.code_presentation)) = course.code_presentation
WHERE assessment.id_assessment IS NOT NULL
  AND assessment.assessment_type IN ('CMA', 'TMA', 'Exam')
  AND assessment.weight BETWEEN 0 AND 100
  AND (assessment.assessment_type = 'Exam' OR assessment.assessment_date IS NOT NULL);

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_silver.vle_clean')
USING DELTA
AS
SELECT
  vle.id_site,
  UPPER(TRIM(vle.code_module)) AS code_module,
  UPPER(TRIM(vle.code_presentation)) AS code_presentation,
  LOWER(TRIM(vle.activity_type)) AS activity_type,
  vle.week_from,
  vle.week_to
FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.vle') AS vle
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean') AS course
  ON UPPER(TRIM(vle.code_module)) = course.code_module
  AND UPPER(TRIM(vle.code_presentation)) = course.code_presentation
WHERE vle.id_site IS NOT NULL
  AND vle.activity_type IS NOT NULL
  AND TRIM(vle.activity_type) <> ''
  AND (
    vle.week_from IS NULL
    OR vle.week_to IS NULL
    OR vle.week_from <= vle.week_to
  );

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean')
USING DELTA
AS
SELECT
  UPPER(TRIM(student.code_module)) AS code_module,
  UPPER(TRIM(student.code_presentation)) AS code_presentation,
  student.id_student,
  student.gender,
  TRIM(student.region) AS region,
  TRIM(student.highest_education) AS highest_education,
  NULLIF(TRIM(student.imd_band), '') AS imd_band,
  TRIM(student.age_band) AS age_band,
  student.num_of_prev_attempts,
  student.studied_credits,
  student.disability,
  student.final_result
FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.student_info') AS student
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.courses_clean') AS course
  ON UPPER(TRIM(student.code_module)) = course.code_module
  AND UPPER(TRIM(student.code_presentation)) = course.code_presentation
WHERE student.id_student IS NOT NULL
  AND student.gender IN ('F', 'M')
  AND student.disability IN ('N', 'Y')
  AND student.final_result IN ('Withdrawn', 'Fail', 'Pass', 'Distinction')
  AND student.num_of_prev_attempts >= 0
  AND student.studied_credits > 0;

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_silver.student_registration_clean')
USING DELTA
AS
SELECT
  UPPER(TRIM(registration.code_module)) AS code_module,
  UPPER(TRIM(registration.code_presentation)) AS code_presentation,
  registration.id_student,
  registration.date_registration,
  registration.date_unregistration
FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.student_registration') AS registration
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean') AS student
  ON UPPER(TRIM(registration.code_module)) = student.code_module
  AND UPPER(TRIM(registration.code_presentation)) = student.code_presentation
  AND registration.id_student = student.id_student
WHERE registration.date_registration IS NULL
  OR registration.date_unregistration IS NULL
  OR registration.date_registration <= registration.date_unregistration;

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_silver.student_assessment_clean')
USING DELTA
AS
SELECT
  submission.id_assessment,
  submission.id_student,
  submission.date_submitted,
  CAST(submission.is_banked AS BOOLEAN) AS is_banked,
  submission.score
FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.student_assessment') AS submission
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.assessments_clean') AS assessment
  ON submission.id_assessment = assessment.id_assessment
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean') AS student
  ON assessment.code_module = student.code_module
  AND assessment.code_presentation = student.code_presentation
  AND submission.id_student = student.id_student
WHERE submission.id_student IS NOT NULL
  AND submission.date_submitted IS NOT NULL
  AND submission.is_banked IN (0, 1)
  AND (submission.score IS NULL OR submission.score BETWEEN 0 AND 100);

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_silver.student_vle_clean')
USING DELTA
AS
SELECT
  UPPER(TRIM(interaction.code_module)) AS code_module,
  UPPER(TRIM(interaction.code_presentation)) AS code_presentation,
  interaction.id_student,
  interaction.id_site,
  interaction.activity_date,
  SUM(interaction.sum_click) AS sum_click
FROM IDENTIFIER(oulad_catalog || '.oulad_bronze.student_vle') AS interaction
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean') AS student
  ON UPPER(TRIM(interaction.code_module)) = student.code_module
  AND UPPER(TRIM(interaction.code_presentation)) = student.code_presentation
  AND interaction.id_student = student.id_student
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.vle_clean') AS activity
  ON UPPER(TRIM(interaction.code_module)) = activity.code_module
  AND UPPER(TRIM(interaction.code_presentation)) = activity.code_presentation
  AND interaction.id_site = activity.id_site
WHERE interaction.activity_date IS NOT NULL
  AND interaction.sum_click > 0
GROUP BY
  UPPER(TRIM(interaction.code_module)),
  UPPER(TRIM(interaction.code_presentation)),
  interaction.id_student,
  interaction.id_site,
  interaction.activity_date;
