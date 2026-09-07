# Validation

Validation SQL lives separately from transformation SQL so checks are easy to review, run, and extend.

| Step | File | Main checks |
| --- | --- | --- |
| Bronze | `tests/03_validate_bronze.sql` | Non-empty sources, natural-key uniqueness, required identifiers, source domains, rescued rows |
| Silver | `tests/05_validate_silver.sql` | Clean-key uniqueness, normalized domains, valid course/student/activity relationships |
| Gold | `tests/08_validate_gold.sql` | Deterministic-key uniqueness, dimension references, fact measures, Silver-to-Gold reconciliation |
| Analytics | `tests/13_validate_analytics.sql` | Output grain, rate bounds, risk domains, student-course reconciliation |

## Result contract

Each test returns a small result set with `PASS` or `FAIL` status. It also calls `ASSERT_TRUE` over the complete result so a failed check stops the Databricks task.

## Adding a production table

Add checks for these categories when they apply:

1. The table is not empty.
2. Its documented key is non-null and unique.
3. Required values are present.
4. Numeric and categorical values are in allowed domains.
5. Foreign keys match the intended parent table.
6. Row counts or aggregates reconcile with the immediate input.

Place the check in the validation file immediately after the transformation’s execution number. This keeps a bad layer from refreshing downstream objects.

## Expected source exceptions

- `imd_band` may be null.
- `date_registration` and `date_unregistration` may be null.
- Exam `assessment_date` may be null.
- Assessment `score` may be null, but non-null scores must be from 0 through 100.
- Bronze `student_vle` may repeat a learner/site/day combination; Silver intentionally aggregates it.

These are modeled as known source semantics rather than silently imputed.
