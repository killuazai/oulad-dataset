# Lecture alignment

| Lecture theme | Repository evidence |
| --- | --- |
| Make data useful and define quality rules | Business questions, explicit expectations, thresholds, severities, owners, and persistent results |
| Frame the problem before selecting data | OULAD questions are documented in the business dashboard and mapped to measures and dimensions |
| Build a repeatable pipeline | Ordered setup, Bronze, Silver, Gold, Analytics, validation, and dashboard-view runners |
| Preserve raw data and clean in stages | Bronze keeps source grain and metadata; Silver standardizes types, categories, relationships, and VLE grain |
| Validate before presenting | A critical quality gate follows every data layer before downstream refresh |
| Use dimensional modeling for BI | Three declared fact grains, six conformed dimensions, and direct fact-to-dimension keys |
| Avoid snowball joins | Gold dimensions never depend on another dimension in the BI model |
| Treat the pipeline as software | Git-friendly SQL files, repository checks, SQL linting, feature-branch workflow, and documented decisions |
| Build a data quality dashboard | Weighted overall, dimension, dataset, issue, history, freshness, and volume views plus a dashboard build guide |
| Keep static ingestion simple | Explicit CSV schemas and deterministic SQL full refresh for the fixed OULAD snapshot |

The repository uses Databricks SQL because the work is relational ingestion, cleaning, joins, aggregation, dimensional modeling, and dashboard serving. PySpark patterns from the course remain appropriate if future volume or transformation complexity exceeds the SQL workflow.
