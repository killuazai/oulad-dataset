# OULAD Business Analytics Genie

## Suggested space description

Answers governed business questions about OULAD learner outcomes, engagement, assessment performance, demographics, and rule-based student risk. This space uses curated analytics views and does not query raw or clean data.

## Add these data objects

- `ftw-week-07.04-analytics.learner_outcomes`
- `ftw-week-07.04-analytics.assessment_performance`
- `ftw-week-07.04-analytics.genie_engagement_outcomes`
- `ftw-week-07.04-analytics.genie_weekly_activity`
- `ftw-week-07.04-analytics.genie_demographic_outcomes`
- `ftw-week-07.04-analytics.genie_risk_summary`

## General instructions to paste into Genie

Use only the curated objects included in this space. Do not invent columns, dates, causal conclusions, or unsupported joins.

“Student enrollment” means one student in one module presentation. Use this term instead of “unique student” unless the selected source explicitly supports a distinct person count.

A successful outcome is `Pass` or `Distinction`. Withdrawal means `final_result = 'Withdrawn'`. Rate columns are stored from 0 to 1; multiply them by 100 and label them as percentages in answers.

`relative_week` is relative to the module presentation start. Negative weeks are activity before the official start and must not be described as calendar weeks.

`total_clicks` measures VLE interactions. It is an engagement indicator, not time spent or proof of learning.

Assessment averages exclude null scores. `late_submission_rate` and `pass_rate` are based on submitted assessment records represented by the curated view.

Risk levels are deterministic screening categories created from engagement, submission, score, and registration rules. They are not probabilities, predictions, diagnoses, or proof that the risk factors caused an outcome. When reporting risk, call it “rule-based risk.”

For demographic rankings, default to groups with at least 20 student enrollments unless the user requests otherwise. Mention this filter in the answer.

Prefer the smallest suitable aggregate view. Do not join the aggregate views together. Order rankings explicitly and use a reasonable limit, normally 10 or 20.

## Recommended sample questions

1. Which module presentations have the highest withdrawal rate?
2. What is the successful outcome rate for each module presentation?
3. How does engagement differ by final result?
4. Show weekly engagement for every module presentation.
5. Which demographic groups have the highest withdrawal rate?
6. Compare assessment performance by module and assessment type.
7. How many high-risk student enrollments are in each module presentation?
8. Does the rule-based risk level align with the observed withdrawal rate?

Use the matching question/SQL pairs in `01_business_analytics_examples.sql` as Genie SQL examples.

