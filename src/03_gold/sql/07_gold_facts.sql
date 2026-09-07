-- Databricks notebook source
-- Name: 07 - Gold Facts
-- Purpose: Build enrollment, assessment submission, and VLE interaction facts.
-- Grain: One row per student-course, student-assessment, or daily student-site interaction.

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_gold.fact_student_course')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS('||', student.code_module, student.code_presentation, CAST(student.id_student AS STRING)),
    256
  ) AS student_course_key,
  course.course_presentation_key,
  learner.student_key,
  student.code_module,
  student.code_presentation,
  student.id_student,
  student.num_of_prev_attempts,
  student.studied_credits,
  registration.date_registration,
  registration.date_unregistration,
  student.final_result
FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_info_clean') AS student
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_course_presentation') AS course
  ON student.code_module = course.code_module
  AND student.code_presentation = course.code_presentation
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_student') AS learner
  ON student.id_student = learner.id_student
LEFT JOIN IDENTIFIER(oulad_catalog || '.oulad_silver.student_registration_clean') AS registration
  ON student.code_module = registration.code_module
  AND student.code_presentation = registration.code_presentation
  AND student.id_student = registration.id_student;

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_gold.fact_assessment_submission')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS('||', CAST(submission.id_assessment AS STRING), CAST(submission.id_student AS STRING)),
    256
  ) AS assessment_submission_key,
  assessment.assessment_key,
  assessment.course_presentation_key,
  learner.student_key,
  submission.id_assessment,
  submission.id_student,
  submission.date_submitted,
  assessment.assessment_date,
  CASE
    WHEN assessment.assessment_date IS NULL THEN NULL
    ELSE submission.date_submitted - assessment.assessment_date
  END AS days_from_due_date,
  submission.is_banked,
  submission.score,
  CASE
    WHEN submission.score IS NULL THEN NULL
    WHEN submission.score >= 40 THEN TRUE
    ELSE FALSE
  END AS passed_assessment
FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_assessment_clean') AS submission
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_assessment') AS assessment
  ON submission.id_assessment = assessment.id_assessment
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_student') AS learner
  ON submission.id_student = learner.id_student;

CREATE OR REPLACE TABLE IDENTIFIER(oulad_catalog || '.oulad_gold.fact_vle_interaction')
USING DELTA
AS
SELECT
  SHA2(
    CONCAT_WS(
      '||',
      interaction.code_module,
      interaction.code_presentation,
      CAST(interaction.id_student AS STRING),
      CAST(interaction.id_site AS STRING),
      CAST(interaction.activity_date AS STRING)
    ),
    256
  ) AS vle_interaction_key,
  activity.vle_activity_key,
  activity.course_presentation_key,
  learner.student_key,
  interaction.code_module,
  interaction.code_presentation,
  interaction.id_student,
  interaction.id_site,
  interaction.activity_date,
  interaction.sum_click
FROM IDENTIFIER(oulad_catalog || '.oulad_silver.student_vle_clean') AS interaction
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_vle_activity') AS activity
  ON interaction.code_module = activity.code_module
  AND interaction.code_presentation = activity.code_presentation
  AND interaction.id_site = activity.id_site
INNER JOIN IDENTIFIER(oulad_catalog || '.oulad_gold.dim_student') AS learner
  ON interaction.id_student = learner.id_student;
