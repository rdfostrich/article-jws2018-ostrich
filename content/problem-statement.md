## Problem statement
{:#problem-statement}

{:.todo}
What is the problem exactly? This is not clear. I think it might be efficiently supporting TPF. All the info is somehow in here, but it needs a clearer flow.

In [previous work](cite:cites tpfarchives), we discussed the requirements for enabling queries over RDF archives using the TPF framework
for VM, DM and VQ queries, with the aim of reaching low-cost RDF archive publication. These requirements are:

1. a feature that extends the [TPF interface](cito:citesAsAuthority ldf) with versioning query types;
2. a storage solution supporting these query types;
3. a TPF client that is able to consume the versioning feature.

The first task was handled through the introduction of [VTPF](cite:cites vtpf),
which is an interface feature for enabling queryable access to RDF archives through VM, DM and VQ triple pattern queries.
The third task is already partially solved by VTPF, as it is designed in such a way that each version of the dataset
is exposed through a separate virtual TPF interface, which allows existing TPF clients to target each version as a separate datasource.

In this article,
we focus on storing and evaluating version materialization (VM), delta materialization (DM), and version (VQ) queries efficiently,
as CV and CM queries can be expressed in [terms of the other ones](cite:cites tpfarchives).
As the publication cost for these archives must be as low as possible,
we focus on lowering query evaluation times by processing and storing more metadata during ingestion time.
That is because this processing then happens only once per version, instead of every time during lookup.

Additionally, as the TPF interface returns triple pattern query results in a _paginated_ way, query results within our store should also be pageable.
This can be achieved by considering the query results as a pull-based stream that can be started at any given offset,
and limited when sufficient elements have been consumed.
The ability to achieve such stream subsets is limited in existing solutions.
Furthermore, the advantage of pull-based streams is that for large amounts of query results,
not every triple should necessarily be kept in memory,
because each resulting element can be consumed and processed by a consumer on-demand.

This leads us to the following research question:
<q id="research-question">How can we store RDF archives to enable efficient VM, DM and VQ triple pattern queries with offsets?</q>

The following requirements can be identified in this research question:

- an efficient RDF archive storage technique;
- VM, DM and VQ triple pattern querying algorithms on top of this storage technique;
- efficient offsetting of the VM, DM, and VQ query result streams.

{:.todo}
hypotheses contain unknown terms (evaluation efficiency, independent, ...) or invalid constructs ("faster or equally fast")

In this work, we introduce solutions to each of these parts in order to come up with an answer to our research question.
To this end, we introduce the following hypotheses:

1. {:#hypothesis-qualitative-querying}
The evaluation efficiency of VM and DM triple pattern queries is independent of the selected versions.
2. {:#hypothesis-qualitative-ic}
Our approach requires *less* storage space than IC-based approaches, but query evaluation is *slower* for VM and *faster* or *equally fast* for DM and VQ.
3. {:#hypothesis-qualitative-cb}
Our approach requires *more* storage space than CB-based approaches, but query evaluation is *faster* or *equally fast*.
4. {:#hypothesis-qualitative-ingestion}
Average query evaluation times are lower than other non-IC approaches, at the cost of increased ingestion time.
