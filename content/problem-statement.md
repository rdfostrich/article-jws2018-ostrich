## Problem statement
{:#problem-statement}

In this section, we present the problem we aim to solve, together with hypotheses about our corresponding solution.

The storage of RDF archives goes hand-in-hand with querying.
[Five foundational query types were introduced](cite:cites bear) that cover the retrieval demands in RDF archiving,
which are referred to as _query atoms_.

1. **Version materialization (VM)** retrieves data using queries targeted at a single version.
Example: _Which books were present in the library yesterday?_
2. **Delta materialization (DM)** retrieves query result differences (i.e. changesets) between two versions.
Example: _Which books were returned or taken from the library between yesterday and now?_
3. **Version query (VQ)** annotates query results with the versions in which they are valid.
Example: _At what times was book X present in the library?_
4. **Cross-version join (CV)** joins the results of two queries between versions.
Example: _What books were present in the library yesterday and today?_
5. **Change materialization (CM)** returns a list of versions in which a given query produces
consecutively different results.
Example: _At what times was book X returned or taken from the library?_

In this article, we will focus on VM, DM, and VQ queries, as CV and CM queries can be expressed in [terms of the other ones](cite:cites tpfarchives).

<span class="comment" data-author="RV">Would there be an organisation to make this paragraph easier to follow? Perhaps split into one paragraph per atom, or one paragraph per aspect (storeage, speed, …)?</span>
There exists a correspondence between these query atoms and the independent copies (IC), change-based (CB), and timestamp-based (TB) storage strategies.
Namely, VM queries are efficient in storage solutions that based on IC, because there is indexing on version.
On the other hand, IC-based solutions may introduce a lot of overhead in terms of storage space because each version is stored separately.
Furthermore, DM and VQ queries are less efficient for IC solutions.
That is because DM queries require two fully-materialized versions to be compared on-the-fly,
and VQ requires _all_ versions to be queried at the same time.
DM queries can be efficient in CB solutions if the query version ranges correspond to the stored delta ranges.
In all other cases, as well as for VM and VQ queries, the desired versions must be materialized on-the-fly,
which will take increasingly more time for longer delta chains.
CB solutions do however typically require less storage space than VM if there is sufficient overlap between each consecutive version.
Finally, VQ queries perform well for TB solutions because the timestamp annotation directly corresponds to VQ's result format.
VM and DM queries in this case are typically less efficient than for IC approaches, due to the missing version index.
Furthermore, TB solutions can require less storage space compared to VM if the change ratio of the dataset is not too large.
In summary, IC, CB and TB approaches can perform well for certain query types, but they can be slow for others.
On the other hand, this efficiency typically comes at the cost of large storage overhead, as is the case for IC-based approaches.

In [previous work](cite:cites tpfarchives), we discussed the requirements for enabling queries over RDF archives using the TPF framework
for VM, DM and VQ queries, with the aim of reaching low-cost RDF archive publication. These requirements are:

1. a feature that extends the [TPF interface](cito:citesAsAuthority ldf) with versioning query types;
2. a storage solution supporting these query types;
3. a TPF client that is able to consume the versioning feature.

The first task was handled through the introduction of [VTPF](cite:cites vtpf),
which is an interface feature for enabling queryable access to RDF archives through VM, DM and VQ triple pattern queries.
The third task is already partially solved by VTPF, as it is designed in such a way that each version of the dataset
is exposed through a separate virtual TPF interface, which allows existing TPF clients to target each version as a separate datasource.

In this work, we focus on the second task, storing and evaluating version materialization (VM), delta materialization (DM), and version (VQ) queries efficiently.
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
<q id="research-question">How can we efficiently store RDF archives while enabling VM, DM and VQ triple pattern queries with efficient offsets?</q>

The following requirements can be identified in this research question:

- an efficient RDF archive storage technique;
- VM, DM and VQ triple pattern querying algorithms on top of this storage technique;
- efficient offsetting of the VM, DM, and VQ query result streams.

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
