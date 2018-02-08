## Statistical Tests
{:#appendix-tests}

This appendix section contains the p-values for the different statistical tests about our hypotheses.

<figure id="hypo-test-1" class="table" markdown="1">

| Dataset       | Query      | Version (p)     | Results (p)     |
| ------------- |:-----------|:----------------|-----------------|
| BEAR-A        | VM         | **0.960**       | **0.570**       |
| BEAR-A        | DM         | **0.301**       | **0.320**       |
| BEAR-B-daily  | VM         | **0.694**       | **0.697**       |
| BEAR-B-daily  | DM         | **0.0391**      |   2.13e-09      |
| BEAR-B-hourly | VM         | **0.568319**    |   0.000574      |
| BEAR-B-hourly | DM         | **0.259**       |   2e-16         |

<figcaption markdown="block">
P-values for the linear regression model factors with the lookup time as response,
and version and number of results as factors for each of the three benchmarks for VM and DM queries.
For all cases, the version factor has no significant influence on the models,
the number of results has an influence in the last three cases.
</figcaption>
</figure>

<figure id="hypo-test-2" class="table" markdown="1">

| Dataset       | Query      | p         | O ≤ H |
| ------------- |:-----------|:----------|-------|
| BEAR-A        | VM         | 1.387e-05 | ✕     |
| BEAR-A        | DM         | < 2.2e-16 | ✕     |
| BEAR-A        | VQ         | < 2.2e-16 | ✕     |
| BEAR-B-daily  | VM         | < 2.2e-16 | ✕     |
| BEAR-B-daily  | DM         | < 2.2e-16 | ✓     |
| BEAR-B-daily  | VQ         | < 2.2e-16 | ✓     |
| BEAR-B-hourly | VM         | < 2.2e-16 | ✕     |
| BEAR-B-hourly | DM         | < 2.2e-16 | ✓     |
| BEAR-B-hourly | VQ         | < 2.2e-16 | ✓     |

<figcaption markdown="block">
P-values for the two-sample t-test for testing equal means between OSTRICH and HDT-IC lookup times
for VM, DM and VQ queries in BEAR-B-daily and BEAR-B-hourly.
The last column indicates whether or not the actual lookup time mean of OSTRICH is less than or equal to HDT-IC.
</figcaption>
</figure>

<figure id="hypo-test-3" class="table" markdown="1">

| Dataset       | Query      | p           | O ≤ H |
| ------------- |:-----------|:------------|-------|
| BEAR-A        | VM         |   1.68e-05  | ✓     |
| BEAR-A        | DM         | < 2.2e-16   | ✓     |
| BEAR-A        | VQ         | < 2.2e-16   | ✕     |
| BEAR-B-daily  | VM         | < 2.2e-16   | ✕     |
| BEAR-B-daily  | DM         | **0.02863** | ✓     |
| BEAR-B-daily  | VQ         | < 2.2e-16   | ✓     |
| BEAR-B-hourly | VM         | < 2.2e-16   | ✓     |
| BEAR-B-hourly | DM         | < 2.2e-16   | ✓     |
| BEAR-B-hourly | VQ         | < 2.2e-16   | ✓     |

<figcaption markdown="block">
P-values for the two-sample t-test for testing equal means between OSTRICH and HDT-CB lookup times
for VM, DM and VQ queries in BEAR-A, BEAR-B-daily and BEAR-B-hourly.
The last column indicates whether or not the actual lookup time mean of OSTRICH is less than or equal to HDT-CB.
</figcaption>
</figure>