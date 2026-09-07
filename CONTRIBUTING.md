# Contributing

## Branch workflow

1. Create a focused branch from `main`.
2. Put exploratory SQL in `queries/`.
3. Put reusable pipeline SQL in the matching numbered `src/` layer.
4. Add or update a validation query in `tests/` for every new production table.
5. Run the local checks before opening a pull request.

```bash
python3 scripts/check_repository.py
sqlfluff lint src tests queries --dialect databricks
```

## SQL conventions

- Use `snake_case` for schemas, tables, columns, and aliases.
- State the purpose and grain at the top of each production SQL file.
- Avoid `SELECT *` in production transformations.
- Qualify production tables with catalog and schema variables through `IDENTIFIER()`.
- Use `TRY_CAST` at ingestion boundaries and make rejected values visible in validation.
- Keep one stable grain per table and document it.
- Prefer explicit column lists so source changes cannot silently alter outputs.

## Numbering

Execution order is encoded in filenames. Insert a new file in its logical layer and update its runner notebook. Do not reuse a number for two production steps.

## Pull request checklist

- [ ] The query has a documented purpose and grain.
- [ ] Inputs and outputs use the intended layer.
- [ ] A corresponding test covers keys, required fields, domains, and relationships.
- [ ] Local structure and SQL checks pass.
- [ ] Documentation reflects any model or threshold change.
