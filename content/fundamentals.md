## Overview: Storage and Querying
{:#fundamentals}

In this section, we lay the groundwork for the following sections.
We introduce fundamental concepts
that are required in our storage approach, which will be explained in [](#storage),
and its accompanying querying algorithms, which will be explained in [](#querying).

To combine smart use of storage space with efficient processing of VM, DM, and VQ triple pattern queries,
we employ a hybrid approach between individual copies (IC), change-based (CB), and timestamp-based (TB) storage technique (as discussed in [](#related-work)).
In summary, intermittent _fully materialized snapshots_ are followed by _delta chains_.
Each delta chain is stored in _tree indexes_, where values are dictionary-encoded and timestamped
in order to reduce storage requirements and lookup times.
Next, each index is replicated for three different triple component orders
to ensure any triple pattern query can be resolved quickly.
Since access patterns to additions and deletions in deltas differ between VM, DM, and VQ queries,
we store additions and deletions in separate tree indexes.
To support inter-delta DM queries, each addition and deletion value contains a _local change_ flag
that indicates if the change is not relative to the snapshot.
Finally, in order to provide cardinality estimation for any triple pattern,
we store an additional count data structure.

In the following sections, we discuss the most important distinguishing features of our approach.
We elaborate on the hybrid IC/CB/TB storage technique that our approach is based on,
the reason for using multiple indexes,
having local change metadata,
and methods for storing addition and deletion counts.

### Snapshot and Delta Chain
{:#snapshot-delta-chain}

Our storage technique is partially based on a hybrid IC/CB approach similar to [](#regular-delta-chain).
To avoid increasing reconstruction times,
we modify the delta chain to be similar to [aggregated deltas](cite:cites vmrdf), i.e., _independent_ of a preceding version.
Instead, deltas are relative to the closest preceding snapshot in the chain, as shown in [](#alternative-delta-chain).
Hence, for any version, version reconstruction only requires at most one delta and one snapshot.
Although this does increase possible redundancies within delta chains,
due to each delta _inheriting_ the changes of its preceding delta,
the overhead can be compensated with compression, which we discuss in [](#storage).

<figure id="alternative-delta-chain">
<img src="img/alternative-delta-chain.svg" alt="[alternative delta chain]">
<figcaption markdown="block">
Delta chain in which deltas are relative to the snapshot at the start of the chain, as part of our approach.
</figcaption>
</figure>

### Multiple Indexes
{:#indexes}

Our storage approach consists of three different indexes that are used for storing additions and deletions
in different triple component orders, namely: `SPO`, `POS` and `OSP`.
These indexes are tree-based, which means the starting triple for any triple pattern can be found in logarithmic time,
and next triples can be found by iterating through the links between each tree leaf.
[](#triple-pattern-index-mapping) shows an overview of which triple patterns can be mapped to which index.
In contrast to [other approaches](cite:cites rdf3x,hexastore),
we use three indexes instead of all six possible component orders,
because we only aim to reduce the iteration scope of the lookup tree for any triple pattern.
For each possible triple pattern,
we now have an index in which the first triple component can be located in logarithmic time,
and the terminating element of the result stream can be identified without necessarily having iterate to the last value of the tree.
Other approaches are typically also interested in ensuring the triple order of the result stream,
so that more efficient stream joining algorithms can be used, such as sort-merge join.
If this would be needed, `OPS`, `PSO` and `SOP` indexes could optionally be added
so that all possible triple orders would be available.

<figure id="triple-pattern-index-mapping" class="table" markdown="1">

| Triple pattern | Index |
| -------------- |-------|
| `S P O`        | `SPO` |
| `S P ?`        | `SPO` |
| `S ? O`        | `OSP` |
| `S ? ?`        | `SPO` |
| `? P O`        | `POS` |
| `? P ?`        | `POS` |
| `? ? O`        | `OSP` |
| `? ? ?`        | `SPO` |


<figcaption markdown="block">
Overview of which triple patterns can be queried inside which index to optimally reduce the iteration scope.
</figcaption>
</figure>

This approach could also act as a pure RDF archiving solution,
without (necessarily efficient) querying capabilities,
in which case only a single index would be required.
By storing only one index, such as `SPO`, the required storage space could be further reduced.
If querying would become required afterwards,
the auxiliary `OSP` and `POS` indexes could still be derived from this main index
during a one-time processing phase before querying.

This technique is similar to the [HDT-FoQ](cite:cites hdtfoq) extension for HDT that adds additional indexes to a basic HDT file
to enable faster querying for any triple pattern.
The main difference is that HDT-FoQ uses the indexes `OSP`, `PSO` and `OPS`,
with a different triple pattern to index mapping as shown in [](#triple-pattern-index-mapping-hdt).
We chose these indexes in order to achieve a more balanced distribution from triple patterns to index,
which could lead to improved load balancing between indexes when queries are parallelized.
Additionally, the mapping from patterns `S?O` to index `SPO` in HDT-FoQ will lead to suboptimal query evaluation
when a large number of distinct predicates is present.
HDT-FoQ uses `SPO` for five triple pattern groups, `OPS` for two and `PSO` for only a single group.
Our approach uses `SPO` for 4 groups, `POS` for two and `OSP` for two.
Future work is needed to evaluate the distribution for real-world queries.

<figure id="triple-pattern-index-mapping-hdt" class="table" markdown="1">

| Triple pattern | Index |
| -------------- |-------|
| `S P O`        | `SPO` |
| `S P ?`        | `SPO` |
| `S ? O`        | `SPO` |
| `S ? ?`        | `SPO` |
| `? P O`        | `OPS` |
| `? P ?`        | `PSO` |
| `? ? O`        | `OPS` |
| `? ? ?`        | `SPO` |


<figcaption markdown="block">
Overview of which triple patterns are queried inside which index in HDT-FoQ.
</figcaption>
</figure>

### Local Changes
{:#local-changes}

A delta chain can contain multiple instances of each triple,
since the same triple could be added in one version and removed in a later one.
Those triples that revert a previous addition or deletion within the same delta chain are called _local changes_
and are important during query evaluation.
Determining the locality of changes can be costly,
thus we pre-calculate this information during ingestion time and store it for each versioned triple,
so that this does not have to happen during query-time.

When evaluating version materialization queries by combining a delta with its snapshot,
all local changes should be filtered out.
For example, a triple `A` that was deleted in version 1, but re-added in version 2,
is cancelled out when materializing against version 2.
For delta materialization, these local changes should be taken into account,
because triple `A` should be marked as a deletion between versions 0 and 1,
but as an addition between versions 1 and 2.
Finally, for version queries, this information is also required
so that the version ranges for each triple can be determined.

### Addition and Deletion counts
{:#addition-deletion-counts}

Parts of our querying algorithms depend on the ability to efficiently count
the _exact_ number of additions or deletions in a delta.
Instead of naively counting triples by iterating over all of them,
we propose two separate approaches for enabling efficient addition and deletion counting in deltas.

For additions, we store an additional mapping from triple pattern and version to number of additions
so that counts can happen in constant time by just looking them up in the map.
For deletions, we store additional metadata in the main deletions tree.
Both of these approaches will be further explained in [](#storage).
