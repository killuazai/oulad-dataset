-- Add each question and its SQL as an example in the Business Analytics Genie space.

-- Question: Which module presentations have the highest withdrawal rate?
SELECT
    code_module,
    code_presentation,
    enrolled_students,
    withdrawn_students,
    ROUND(100 * withdrawal_rate, 2) AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.`learner_outcomes`
ORDER BY withdrawal_rate DESC, enrolled_students DESC;

-- Question: What is the successful outcome rate for each module presentation?
SELECT
    code_module,
    code_presentation,
    enrolled_students,
    passed_students,
    distinction_students,
    ROUND(100 * successful_outcome_rate, 2) AS successful_outcome_rate_pct
FROM `ftw-week-07`.`04-analytics`.`learner_outcomes`
ORDER BY successful_outcome_rate DESC;

-- Question: How does engagement differ by final result?
SELECT
    final_result,
    student_enrollments,
    average_active_days,
    average_activities_used,
    average_total_clicks,
    median_total_clicks
FROM `ftw-week-07`.`04-analytics`.`genie_engagement_outcomes`
ORDER BY average_total_clicks DESC;

-- Question: Show weekly engagement for every module presentation.
SELECT
    code_module,
    code_presentation,
    relative_week,
    total_clicks,
    active_students,
    student_site_days,
    average_clicks_per_active_student
FROM `ftw-week-07`.`04-analytics`.`genie_weekly_activity`
ORDER BY code_module, code_presentation, relative_week;

-- Question: Which demographic groups have the highest withdrawal rate?
SELECT
    gender,
    age_band,
    highest_education,
    imd_band,
    student_enrollments,
    withdrawn_students,
    ROUND(100 * withdrawal_rate, 2) AS withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.`genie_demographic_outcomes`
WHERE student_enrollments >= 20
ORDER BY withdrawal_rate DESC, student_enrollments DESC
LIMIT 20;

-- Question: Compare assessment performance by module and assessment type.
SELECT
    code_module,
    code_presentation,
    assessment_type,
    submission_count,
    submitting_students,
    average_score,
    median_score,
    ROUND(100 * pass_rate, 2) AS pass_rate_pct,
    ROUND(100 * late_submission_rate, 2) AS late_submission_rate_pct
FROM `ftw-week-07`.`04-analytics`.`assessment_performance`
ORDER BY code_module, code_presentation, assessment_type;

-- Question: How many high-risk student enrollments are in each module presentation?
SELECT
    code_module,
    code_presentation,
    student_enrollments AS high_risk_enrollments,
    withdrawn_students,
    average_risk_score,
    average_total_clicks,
    average_assessment_score,
    ROUND(100 * actual_withdrawal_rate, 2) AS actual_withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.`genie_risk_summary`
WHERE risk_level = 'HIGH'
ORDER BY high_risk_enrollments DESC;

-- Question: Does the risk level align with the observed withdrawal rate?
SELECT
    risk_level,
    SUM(student_enrollments) AS student_enrollments,
    SUM(withdrawn_students) AS withdrawn_students,
    ROUND(
        100.0 * SUM(withdrawn_students) / NULLIF(SUM(student_enrollments), 0),
        2
    ) AS observed_withdrawal_rate_pct
FROM `ftw-week-07`.`04-analytics`.`genie_risk_summary`
GROUP BY
    risk_level,
    risk_level_order
ORDER BY risk_level_order;
