# Architecture

## End-to-end flow

```mermaid
flowchart LR
    S[Seven CSV files] --> B[Bronze]
    B --> QB[Bronze DQ]
    QB --> C[Silver]
    C --> QS[Silver DQ]
    QS --> GD[Gold dimensions]
    QS --> GF[Gold facts]
    GD --> QG[Gold DQ]
    GF --> QG
    QG --> A[Four Analytics tables]
    A --> QA[Analytics DQ<br/>including Accuracy reconciliation]
    QA --> DV[Core DQ views]
    DV --> GV[Governed Genie/dashboard views]
    GV --> BD[Business dashboard]
    GV --> DD[DQ dashboard]
```

OULAD is a fixed research snapshot, so transformation tables use deterministic full refreshes. `dq_check_results` is append-only for audit and trend analysis.

## Failure boundaries

- Setup stops when the source directory does not contain exactly the expected seven CSV files.
- Every transformed layer is followed by a critical gate.
- Reconciliation stops dashboard refresh when control totals change across layers.
- Noncritical known conditions remain visible as warnings.
- Dashboard source views refresh only after all four validation suites succeed; the Analytics suite includes the cross-layer Accuracy gate.

## Cost and scalability

- Explicit CSV schemas avoid inference scans.
- Silver consolidates VLE events once at the required grain.
- Gold uses deterministic direct keys and avoids snowball joins.
- Dashboards and Genie query small governed aggregates where possible.
- Historical DQ queries run only for trend/drill-down use cases.
- For substantially larger facts, compact numeric surrogate keys can replace SHA-256 strings if changed consistently across dimensions, facts, tests, and BI relationships.
