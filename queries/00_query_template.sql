-- Query: Rename this file and describe the question being answered.
-- Grain: Describe what one output row represents.
-- Safety: Keep this file read-only until the logic belongs in a numbered pipeline step.

DECLARE OR REPLACE VARIABLE query_catalog STRING DEFAULT 'workspace';

SELECT
  code_module,
  code_presentation,
  enrolled_students,
  successful_outcome_rate,
  withdrawal_rate
FROM IDENTIFIER(query_catalog || '.oulad_analytics.learner_outcomes')
ORDER BY
  code_module,
  code_presentation;
