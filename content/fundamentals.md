## Fundamentals
{:#fundamentals}

In this section, we introduce some fundamental concepts
that are required in our storage approach and its accompanying querying algorithms.
We discuss our hybrid IC/CB/TB storage approach,
the reason for using multiple indexes,
having local change metadata,
and methods for storing addition and deletion counts.

### Snapshot and Delta Chain
{:#snapshot-delta-chain}

As mentioned before in [](#preliminaries), we can distinguish individual copies (IC),
change-based (CB) or timestamp-based storage strategies in RDF archiving solutions.
While IC is optimal for querying specific version, it introduces a lot of storage overhead when there is are redundancies between each version.
On the other hand, CB is good for querying differences between versions, but is less efficient for querying specific versions as it requires
reconstructing versions based on a complete delta chain.
In this section, we discuss the hybrid IC/CB approach that our approach is based on.

[TailR](cite:cites tailr) is a hybrid IC/CB approach in which delta chain lengths are limited
to reduce the cost of reconstructing arbitrary versions in long chains.
This is done by starting each chain with a fully materialized snapshot, followed by deltas, as shown in [](#regular-delta-chain).
When the chain becomes too long, or other conditions are fulfilled, the chain stops
and a new snapshot is created for the next version.

<figure id="regular-delta-chain">
<img src="img/regular-delta-chain.svg" alt="[regular delta chain]">
<figcaption markdown="block">
Delta chain in which deltas are relative to the previous delta, as is done in [TailR](cite:cites tailr).
</figcaption>
</figure>

Results show that this is an effective way of [reducing version reconstruction times](cite:cites tailr),
but within the delta chain, an increase in version reconstruction times can still be observed.
In order to avoid these increasing reconstruction times,
we modify the delta chain structure slightly to make these times constant _independent_ of version, similar to [aggregated deltas](cite:cites vmrdf).
Instead of making deltas relative to each preceding delta,
we make them relative to the closest preceding snapshot in the chain, as shown in [](#alternative-delta-chain).
This allows version reconstruction to require only at most one delta and one snapshot for any version.
While this does increase possible redundancies within delta chains, this can easily be compressed away,
which we discuss in [](#storage).

<figure id="alternative-delta-chain">
<img src="img/alternative-delta-chain.svg" alt="[alternative delta chain]">
<figcaption markdown="block">
Delta chain in which deltas are relative to the snapshot at the start of the chain, as part of our approach.
</figcaption>
</figure>

### Multiple Indexes

Our storage approach consists of three different indexes that are used for storing additions and deletions
in different triple component orders, namely: `SPO`, `POS` and `OSP`.
The reason for five indexes instead of all six possible component orders,
as is typically done in [other approaches](cite:cites rdf3x,hexastore),
is because we only aim to evaluate all triple pattern queries efficiently without having to go over the whole index.
Other approaches are typically also interested in the final triple order for more efficient joining of streams.
If this would be needed, `OPS`, `PSO` and `SOP` indexes could optionally be added.

The three indexes that were mentioned are sufficient for optimally reducing the iteration scope of the lookup tree for any triple pattern.
That is because for each possible triple pattern,
there exists an index at which the first triple component can be located in logarithmic time,
and the terminating element of the result stream can be identified without necessarily having to go to the last value of the tree.

The optimal index can always be identified by reordering the triple components of the incoming triple pattern
by ensuring that all variable components come before the non-variable ones.
After that, an index that corresponds to the given triple component order can be used.
`OPS`, `PSO` and `SOP` indexes are not required because triple components for this can be reordered without a loss of expressivity.
[](#triple-pattern-index-mapping) shows an overview of which triple patterns can be mapped to which index.

For example, for an `S?O` query, the components are reordered to `OS?`, which corresponds to the `OSP` index.
In this case, the first `OS?` triple can be found in logarithmic time.
From the moment a triple is found where the object is larger than `S`,
we can terminate the stream because no new matching triples will be found.

<figure id="triple-pattern-index-mapping" class="table" markdown="1">

| Triple pattern | Index |
| -------------- |-------|
| S P O          | SPO   |
| S P ?          | SPO   |
| S ? O          | OSP   |
| S ? ?          | SPO   |
| ? P O          | POS   |
| ? P ?          | POS   |
| ? ? O          | OSP   |
| ? ? ?          | SPO   |


<figcaption markdown="block">
Overview of which triple patterns can be queried inside which index to optimally reduce the iteration scope.
</figcaption>
</figure>

### Local Changes

When materializing versions by combining a delta with its snapshot,
it is important to know whether or not the delta element is relative to the snapshot or a previous delta.
Because a triple that for example was deleted in version 1, but re-added in version 2
is cancelled out when materializing against version 2.

One way of doing this is by checking both the addition and deletion trees for a given triple and version,
and determining the element with the smallest version.
All elements with version larger than this smallest version will be local changes.

An alternative approach would be to precalculate this information
and store it on each value, as is done in our [storage approach](#storage).

The first approach always requires lookups in both trees,
even if only the additions or deletions are queried.
On the other hand, it requires less storage space,
because storage of the local changes requires the storage of one additional flag per triple per version.

### Addition and Deletion counts

Parts of our querying algorithms depend on the ability to efficiently count
the number of additions or deletions in a delta.
A naive way of doing this would be to simply iterate over all triples in a delta,
and counting all those matching the triple pattern and version.
This has a linear time complexity in terms of the total number of triples, so this will not perform well for large stores.
We propose two separate approaches for enabling efficient addition and deletion counting in deltas.

For additions, we propose to store an additional mapping from triple pattern and version to number of additions
so that counts can happen in constant time by just looking them up in the map.
For deletions, we store additional metadata in the main deletions tree.
Both of these approaches will be further explained in [](#storage).
