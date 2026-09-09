# Assignment alignment

| Professor instruction | Implemented here |
|---|---|
| Ingest CSVs into raw | Explicit-schema Bronze Delta tables |
| Standardize types and handle missing values | Silver cleaning and validation |
| Facts: FactAssessments and FactVLEInteractions | Exactly `fact_assessments` and `fact_vle_interactions` |
| Dimensions: Student, Course, Module Presentation, Date, Demographics | Exactly five physical dimensions |
| Model event-based and aggregated facts | Assessment submission event plus daily aggregated VLE interaction |
| Implement in dbt mart schema | `dbt_project.yml` and seven mart models |
| Analyze cohorts, dropout risk, and engagement | Supporting cohort/risk models and Metabase SQL pack |
| Scale, trust, reliability | Explicit grains, validation gates, and control-total reconciliation |

Databricks Lakeview and Genie assets are optional portfolio additions. Metabase
is the required dashboard implementation target.
