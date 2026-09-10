# Final alignment findings and upload order

## Findings

The previous repository was internally consistent but did not match the
professor's explicit dimensional-model scope. It had three Gold facts, six
physical dimensions, no dbt project, and Databricks dashboards instead of a
Metabase implementation pack.

This revision corrects those gaps:

1. The core mart now has exactly two facts and five dimensions.
2. Course and Module Presentation are separated at their correct grains.
3. Assessment and VLE descriptors move into their required facts.
4. Enrollment becomes the supporting Analytics `student_cohort`, not a Gold fact.
5. Both facts connect directly to Student, Course, Module Presentation, Date,
   and Demographics.
6. The two assessment date keys both reference the same `dim_date` primary key.
7. A complete dbt mart and relationship tests are included.
8. Metabase query and build packs are included for both the Business and Data
   Quality dashboards.
9. Databricks SQL, Analytics, DQ, and Genie references now use the new names.
10. Accuracy remains consolidated in Analytics validation.
11. The approved final schema adds `final_result` and derived `is_withdrawn` to
    `dim_demographics`; the deterministic key includes `final_result`.
12. The VLE fact grain is module + presentation + student + site + relative day,
    and its Date foreign key follows the approved `activity_date_id` name.

## Recommended upload and run order

1. Replace repository files with this revision.
2. Run Setup, Bronze, Bronze Validation, Silver, and Silver Validation.
3. Run `src/03_gold/sql/05_reset_gold_model.sql` once to remove the old Gold model.
4. Configure `profiles.yml` from `profiles.yml.example`.
5. Run `dbt build --select path:models/mart`.
6. Run `notebooks/06_run_after_dbt.sql`.
7. Build the Metabase Business and Data Quality dashboards from the two query
   packs documented in `metabase/README.md`.
8. Run `python3 scripts/check_repository.py` locally before opening the PR.

The Databricks-only full runner is preserved for demonstration, but the dbt path
is the submission-aligned implementation.
