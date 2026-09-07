-- Databricks notebook source
-- Dataset: Engagement versus outcome
SELECT
  final_result,
  COUNT(*) AS enrolled_students,
  AVG(active_days) AS average_active_days,
  AVG(total_clicks) AS average_total_clicks,
  PERCENTILE_APPROX(total_clicks, 0.5) AS median_total_clicks
FROM workspace.oulad_analytics.student_engagement
GROUP BY final_result
ORDER BY average_total_clicks DESC;

-- COMMAND ----------

-- Dataset: Withdrawal patterns
SELECT
  code_module,
  code_presentation,
  enrolled_students,
  withdrawn_students,
  withdrawal_rate
FROM workspace.oulad_analytics.learner_outcomes
ORDER BY withdrawal_rate DESC;

-- COMMAND ----------

-- Dataset: Activity over relative course week
SELECT
  activity_date.relative_week,
  module.code_module,
  module.code_presentation,
  SUM(interaction.sum_click) AS total_clicks,
  COUNT(DISTINCT interaction.student_key) AS active_students
FROM workspace.oulad_gold.fact_vle_interaction AS interaction
INNER JOIN workspace.oulad_gold.dim_relative_date AS activity_date
  ON interaction.activity_date_key = activity_date.relative_date_key
INNER JOIN workspace.oulad_gold.dim_module_presentation AS module
  ON interaction.module_presentation_key = module.module_presentation_key
GROUP BY
  activity_date.relative_week,
  module.code_module,
  module.code_presentation
ORDER BY
  module.code_module,
  module.code_presentation,
  activity_date.relative_week;

-- COMMAND ----------

-- Dataset: Outcomes by demographic profile
SELECT
  demographics.gender,
  demographics.age_band,
  demographics.highest_education,
  demographics.imd_band,
  COUNT(*) AS enrolled_students,
  AVG(enrollment.withdrawn_count) AS withdrawal_rate,
  AVG(enrollment.passed_count + enrollment.distinction_count) AS successful_outcome_rate
FROM workspace.oulad_gold.fact_student_enrollment AS enrollment
INNER JOIN workspace.oulad_gold.dim_demographics AS demographics
  ON enrollment.demographics_key = demographics.demographics_key
GROUP BY
  demographics.gender,
  demographics.age_band,
  demographics.highest_education,
  demographics.imd_band;

-- COMMAND ----------

-- Dataset: Late submissions and performance
SELECT
  module.code_module,
  assessment.assessment_type,
  AVG(CASE WHEN submission.days_from_due_date > 0 THEN 1.0 ELSE 0.0 END) AS late_submission_rate,
  AVG(submission.score) AS average_score,
  AVG(CASE WHEN submission.passed_assessment IS NULL THEN NULL
    WHEN submission.passed_assessment THEN 1.0 ELSE 0.0 END) AS assessment_pass_rate
FROM workspace.oulad_gold.fact_assessment_submission AS submission
INNER JOIN workspace.oulad_gold.dim_module_presentation AS module
  ON submission.module_presentation_key = module.module_presentation_key
INNER JOIN workspace.oulad_gold.dim_assessment AS assessment
  ON submission.assessment_key = assessment.assessment_key
GROUP BY
  module.code_module,
  assessment.assessment_type;
