-- Databricks notebook source
-- Build and validate the Analytics layer after Gold succeeds.

-- COMMAND ----------

-- MAGIC %run ../src/00_setup/01_setup

-- COMMAND ----------

-- MAGIC %run ../src/04_analytics/sql/09_learner_outcomes

-- COMMAND ----------

-- MAGIC %run ../src/04_analytics/sql/10_student_engagement

-- COMMAND ----------

-- MAGIC %run ../src/04_analytics/sql/11_assessment_performance

-- COMMAND ----------

-- MAGIC %run ../src/04_analytics/sql/12_at_risk_students

-- COMMAND ----------

-- MAGIC %run ../tests/13_validate_analytics

-- COMMAND ----------

-- MAGIC %run ../src/05_data_quality/sql/14_dq_dashboard_views
