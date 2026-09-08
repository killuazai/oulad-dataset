-- Databricks notebook source
-- Name: 08 - Gold Relationships
-- Purpose: Declare informational PK/FK metadata for the Catalog Explorer ERD.
-- Prerequisite: Gold dimensions, facts, and critical validation checks must pass.

-- Remove this project's foreign keys first so the script can be rerun safely.
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  DROP CONSTRAINT IF EXISTS fk_enrollment_student;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  DROP CONSTRAINT IF EXISTS fk_enrollment_demographics;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  DROP CONSTRAINT IF EXISTS fk_enrollment_module_presentation;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  DROP CONSTRAINT IF EXISTS fk_enrollment_registration_date;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  DROP CONSTRAINT IF EXISTS fk_enrollment_unregistration_date;

ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  DROP CONSTRAINT IF EXISTS fk_submission_student;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  DROP CONSTRAINT IF EXISTS fk_submission_demographics;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  DROP CONSTRAINT IF EXISTS fk_submission_module_presentation;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  DROP CONSTRAINT IF EXISTS fk_submission_assessment;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  DROP CONSTRAINT IF EXISTS fk_submission_submitted_date;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  DROP CONSTRAINT IF EXISTS fk_submission_due_date;

ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  DROP CONSTRAINT IF EXISTS fk_vle_student;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  DROP CONSTRAINT IF EXISTS fk_vle_demographics;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  DROP CONSTRAINT IF EXISTS fk_vle_module_presentation;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  DROP CONSTRAINT IF EXISTS fk_vle_activity;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  DROP CONSTRAINT IF EXISTS fk_vle_activity_date;

-- Remove this project's primary keys after their foreign keys are gone.
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  DROP CONSTRAINT IF EXISTS pk_fact_student_enrollment;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  DROP CONSTRAINT IF EXISTS pk_fact_assessment_submission;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  DROP CONSTRAINT IF EXISTS pk_fact_vle_interaction;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_student
  DROP CONSTRAINT IF EXISTS pk_dim_student;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_demographics
  DROP CONSTRAINT IF EXISTS pk_dim_demographics;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_module_presentation
  DROP CONSTRAINT IF EXISTS pk_dim_module_presentation;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_assessment
  DROP CONSTRAINT IF EXISTS pk_dim_assessment;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_vle_activity
  DROP CONSTRAINT IF EXISTS pk_dim_vle_activity;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_relative_date
  DROP CONSTRAINT IF EXISTS pk_dim_relative_date;

-- Databricks requires primary-key columns to be NOT NULL.
ALTER TABLE `ftw-week-07`.`03-mart`.dim_student
  ALTER COLUMN student_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_demographics
  ALTER COLUMN demographics_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_module_presentation
  ALTER COLUMN module_presentation_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_assessment
  ALTER COLUMN assessment_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_vle_activity
  ALTER COLUMN vle_activity_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.dim_relative_date
  ALTER COLUMN relative_date_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  ALTER COLUMN student_enrollment_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  ALTER COLUMN assessment_submission_key SET NOT NULL;
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  ALTER COLUMN vle_interaction_key SET NOT NULL;

-- Dimension and fact primary keys.
ALTER TABLE `ftw-week-07`.`03-mart`.dim_student
  ADD CONSTRAINT pk_dim_student PRIMARY KEY (student_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_demographics
  ADD CONSTRAINT pk_dim_demographics PRIMARY KEY (demographics_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_module_presentation
  ADD CONSTRAINT pk_dim_module_presentation PRIMARY KEY (module_presentation_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_assessment
  ADD CONSTRAINT pk_dim_assessment PRIMARY KEY (assessment_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_vle_activity
  ADD CONSTRAINT pk_dim_vle_activity PRIMARY KEY (vle_activity_key);
ALTER TABLE `ftw-week-07`.`03-mart`.dim_relative_date
  ADD CONSTRAINT pk_dim_relative_date PRIMARY KEY (relative_date_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  ADD CONSTRAINT pk_fact_student_enrollment PRIMARY KEY (student_enrollment_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  ADD CONSTRAINT pk_fact_assessment_submission PRIMARY KEY (assessment_submission_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  ADD CONSTRAINT pk_fact_vle_interaction PRIMARY KEY (vle_interaction_key);

-- Enrollment star.
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  ADD CONSTRAINT fk_enrollment_student
  FOREIGN KEY (student_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_student (student_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  ADD CONSTRAINT fk_enrollment_demographics
  FOREIGN KEY (demographics_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_demographics (demographics_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  ADD CONSTRAINT fk_enrollment_module_presentation
  FOREIGN KEY (module_presentation_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_module_presentation (module_presentation_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  ADD CONSTRAINT fk_enrollment_registration_date
  FOREIGN KEY (registration_date_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_relative_date (relative_date_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_student_enrollment
  ADD CONSTRAINT fk_enrollment_unregistration_date
  FOREIGN KEY (unregistration_date_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_relative_date (relative_date_key);

-- Assessment-submission star.
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  ADD CONSTRAINT fk_submission_student
  FOREIGN KEY (student_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_student (student_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  ADD CONSTRAINT fk_submission_demographics
  FOREIGN KEY (demographics_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_demographics (demographics_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  ADD CONSTRAINT fk_submission_module_presentation
  FOREIGN KEY (module_presentation_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_module_presentation (module_presentation_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  ADD CONSTRAINT fk_submission_assessment
  FOREIGN KEY (assessment_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_assessment (assessment_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  ADD CONSTRAINT fk_submission_submitted_date
  FOREIGN KEY (submitted_date_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_relative_date (relative_date_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_assessment_submission
  ADD CONSTRAINT fk_submission_due_date
  FOREIGN KEY (due_date_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_relative_date (relative_date_key);

-- VLE-interaction star.
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  ADD CONSTRAINT fk_vle_student
  FOREIGN KEY (student_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_student (student_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  ADD CONSTRAINT fk_vle_demographics
  FOREIGN KEY (demographics_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_demographics (demographics_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  ADD CONSTRAINT fk_vle_module_presentation
  FOREIGN KEY (module_presentation_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_module_presentation (module_presentation_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  ADD CONSTRAINT fk_vle_activity
  FOREIGN KEY (vle_activity_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_vle_activity (vle_activity_key);
ALTER TABLE `ftw-week-07`.`03-mart`.fact_vle_interaction
  ADD CONSTRAINT fk_vle_activity_date
  FOREIGN KEY (activity_date_key)
  REFERENCES `ftw-week-07`.`03-mart`.dim_relative_date (relative_date_key);

-- Verification result: expect 25 constraints (9 PK + 16 FK).
SELECT
  table_name,
  constraint_name,
  constraint_type
FROM `ftw-week-07`.information_schema.table_constraints
WHERE table_schema = '03-mart'
  AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY table_name, constraint_type, constraint_name;
