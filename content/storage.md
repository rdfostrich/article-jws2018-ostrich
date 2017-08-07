## Storage
{:#storage}

In this section, we introduce a storage approach for storing multiple versions of an RDF dataset.
We focus on the part of answering our research question on how to efficiently store and query RDF archives, as introduced in [](#introduction).

In order to handle VM, DM and VQ queries efficiently, our storage solution is a hybrid IC/CB/TB triple store, as introduced in last section.
In summary, our approach consists of an initial dataset snapshot followed by a delta chain ([TailR](cite:cites tailr)),
where this chain is compressed in B+Trees for TB-storage ([Dydra](cite:cites dydra)).
Furthermore, we store additional metadata for improving lookup times ([HDT](cite:cites hdt)).
Triple components are encoded in a dictionary for improved compression ([HDT](cite:cites hdt))
and we provide multiple indexes for different triple component orders ([RDF-3X](cite:cites rdf3x), [Hexastore](cite:cites hexastore)).
[](#storage-overview) shows an overview of these main components, which will be explained in more detail in the following sections.
We end this section with a description of two ingestion algorithms for this storage approach:
one batch algorithm, which requires loading the versions in-memory,
and one memory-efficient streaming algorithm, which inserts the versions in small-chunks.

<figure id="storage-overview">
<img src="img/storage-overview.svg" alt="[storage overview]">
<figcaption markdown="block">
The initial version of an RDF archive is stored as a _fully materialized snapshot_, for example using the HDT format.
Each following version is stored as a _delta_ relative to the initial snapshot.
All delta's are compressed in _addition and deletion trees_, where a _dictionary_ is used to compress triple components.
Furthermore, we store the _counts_ for certain triple pattern queries over _additions_.
Finally, metadata about the complete archive is stored, containing information such as the total number of available versions.
</figcaption>
</figure>

### Snapshot storage
{:#snapshot-storage}

As mention before, the start of each delta chain is a fully materialized snapshot.
In order to provide sufficient efficiency for VM, DM and VQ querying with respect to all versions in the chain,
we assume the following requirements for the snapshot storage:

{:.todo}
Using underscores for emphasis doesn't work in list below.

<ol>
    <li>Any triple pattern query _must_ be efficiently resolvable as triple streams.</li>
    <li>Offsets _must_ be efficiently applicable to the result stream of any triple pattern query.</li>
    <li>All triple components _must_ be dictionary-encoded.</li>
    <li>Total result counts for all triple pattern queries _should_ be efficiently resolvable.</li>
</ol>

These requirements are needed for ensuring the efficiency of the querying algorithms that will be introduced in [](#querying).
Providing an implementation for a snapshot store is out of scope for this work,
but existing techniques such as [HDT](cite:cites hdt) fulfill all these requirements.

### Delta Storage
{:#delta-storage}

In order to cope with the newly introduced redundancies in our delta chain structure,
we introduce a delta storage method similar to the TB storage strategy,
which is able to compress redundancies within consecutive deltas.

The additions and deletions of deltas require different metadata in our querying algorithms,
which will be explained in [](#querying).
That is why we store these in separate addition and deletion stores.
All additions and deletions from the complete delta chain are respectively stored together.
We use a tree structure (such as a B+Tree) for these addition and deletion stores,
where the keys correspond to triples and the values correspond to version information,
which are similar to timestamps in TB solutions.
Even though triples can exist in multiple deltas in the same chain,
they will only be stored once in the trees because their value contains information about version membership.

In order to improve the efficiency during triple pattern query evaluation,
we store the trees in different triple component orders,
similar to [RDF-3X](cite:cites rdf3x) and [Hexastore](cite:cites hexastore).
Our approach consists of three orders per addition and deletion tree: SPO, POS and OSP.
These three indexes are sufficient for optimally resolving any triple pattern, as discussed in [](#indexes).

In order to further speed up query evaluation,
we add metadata to each triple indicating whether or not the triple is a _local change_, as mentioned in [](#local-changes).
A triple is a local change in a certain version if it was already either added or removed in an earlier version.
This local change information helps the querying algorithm to determine when to ignore a triple or not,
which will be further explained in [](#querying).

Finally, in order to speed up the process of patching a snapshot's triple pattern subset for any given offset,
we add metadata about the relative position of each triple inside the delta to the deletion trees.
This position information has two purposes:
1) it allows the querying algorithm to exploit offset capabilities of the snapshot store
to resolve offsets for any triple pattern against any version;
and 2) it allows deletion counts for any triple pattern and version to be determined efficiently.
This process will also be further explained in [](#querying).

In summary, we store six trees, three for both the additions and deletions.
The trees use triples as keys, with three different triple component orders.
The addition trees store version and local change information.
The deletion trees store the same, but additionally also relative snapshot positions.

### Delta Chain Dictionary
{:#dictionary}

A typical technique in [RDF storage solutions](cite:cites hdt,rdf3x,triplebit) is to use a dictionary for mapping triple components to numerical IDs.
This is generally done for main two reasons:
1) to reduce storage space if triple components are stored multiple times;
2) to simplify and optimize querying.
As our storage approach essentially stores each triple three or six times,
a dictionary can definitely reduce storage space requirements.

Each delta chain consists of two dictionaries, one for the snapshot and one for the deltas.
The dictionary of the snapshot can be optimized and sorted, as it will not change over time.
The dictionary of the deltas is volatile, as each new version can introduce new mappings.

During triple encoding, the snapshot dictionary will always first be queried for existence of the triple component.
If there is a match, that ID is used for storing the delta's triple component.

For allowing the querying algorithm to identify the appropriate dictionary for triple decoding,
some form of dictionary identification must be encoded inside the ID,
which can for example be a reserved bit.

As the dictionary entries are text-based, they are likely to contain a lot of redundancies.
That is why the dictionary can be compressed to reduce storage space.

### Addition Counts
{:#addition-counts}

As mentioned before in [](#addition-deletion-counts),
in order to make the counting of matching addition triples for any triple pattern for any version more efficient,
we propose to store an additional mapping from triple pattern and version to the number of matching additions.
Furthermore, for being able to retrieve the total number of additions across all versions,
we also propose to store this value for all triple patterns.
This mapping must be calculated during ingestion time, so that counts during lookup time for any triple pattern
at any version can be derived in constant time.
For many triples and versions, the number of possible triple patterns can become very large,
which can result in a large mapping store.
To cope with this, we propose to only store the elements where their counts are larger than a certain threshold.
Elements that are not stored will have to be counted during lookup time.
This is however not a problem for reasonably low thresholds,
because as mentioned in [](#addition-deletion-counts),
We can efficiently limit the iteration scope in our indexes,
so that for triple patterns for which only a limited number of matches exist,
iteration, and therefore the counts, can happen efficiently.
The count threshold introduces a trade-off between the storage requirements and the required triple counting during lookups.

### Deletion Counts
{:#deletion counts}

As mentioned in [](#delta-storage), each deletion is annotated with its relative position in all deletions for that version.
We can exploit this information to perform deletion counting for any triple pattern and version.
This can be done by looking up the largest possible triple for the given triple pattern in the deletions tree,
which can be done in logarithmic time.
If this doesn't result in a match, we follow backward links to the elements before that one in the tree.
In this value, the position of the deletion in all deletions for the given value is available.
Because we have queried the largest possible triple for that triple pattern in the given version,
this will be the last deletion in the list, so its position corresponds to the total number of deletions in that case.

### Metadata
{:#metadata}

In order to allow querying algorithms to detect the total number of versions across all delta chains,
we must store metadata regarding the delta chain version ranges.
Assuming numerical version identifiers, a mapping can be maintained from version ID to delta chain.
Additionally, a total version counter must be maintained for cases when the last version must be identified.

### Ingestion

In the following two subsections, we discuss an in-memory batch and a streaming ingestion algorithm.
These algorithms both take a changeset — containing additions and deletions — as input,
and ingest it to the store as a new version.
Note that the ingested changesets are regular changesets, i.e., they are relative to one another according to [](#regular-delta-chain).
Furthermore, we assume that the ingested changesets are valid changesets, i.e.,
they don't contain impossible triple sequences such as a triple that is removed in two versions without having an addition inbetween.
During ingestion, they will be transformed to the alternative delta chain structure as shown in [](#alternative-delta-chain).
Within the scope of this article, we only discuss ingestion of deltas in a single delta chain following a snapshot.
The creation of snapshots at the start of each new chain and determining suitable moments to create a snapshot instead of a delta
is considered as future work.

Next to ingesting the added and removed triples,
an ingestion algorithm for our storage approach must be able to calculate
the appropriate metadata for the store as discussed in [](#delta-storage).
More specifically, an ingestion algorithm has the following requirements:
<ul>
    <li>Addition triples must be stored in all addition trees</li>
    <li>Additions and deletions must be annotated with their version</li>
    <li>Additions and deletions must be annotated with being a local change or not</li>
    <li>Deletions must be annotated with their position for all triple patterns</li>
</ul>

#### Batch Ingestion
{:#batch-ingestion}

Our first algorithm to ingest data into the store naively loads everything in memory,
and inserts the data accordingly.
The advantage of this algorithm is its simplicity and the possibility to do straightforward optimizations during ingestion.
The main disadvantage is the high memory consumption requirement for large versions.

Before we discuss the actual batch ingestion algorithm,
we first introduce an in-memory changeset merging algorithm,
which is required for the batch ingestion.
[](#algorithm-ingestion-batch-merge) shows the pseudocode of an algorithm for merging a changeset into another changeset,
and returning the resulting merged changeset.
First, all contents of the original changeset are copied into the new changeset.
After that, an iteration over all triples of the second changeset is started.
If the changeset already contained the given triple, the local change flag is set to the negation of the local change flag in the first changeset.
Otherwise, the triple is added to the new changeset, and the local change flag is set to `false`.
Finally, in both cases the addition flag of the triple in the new changeset is copied from the second changeset.

<figure id="algorithm-ingestion-batch-merge" class="algorithm">
````/algorithms/ingestion-batch-merge.txt````
<figcaption markdown="block">
In-memory changeset merging algorithm
</figcaption>
</figure>

Secondly, we also introduce an algorithm for incrementally calculating the position of a deletion within a changeset in [](#algorithm-positions).
For this, we externally maintain mappings from triple to a counter for each possible triple pattern.
For the `???` triple pattern, we only have to maintain a single counter, as each triple will match with this.
In total, we maintain seven triple patterns per triple, we don't maintain a counter for the triple itself as its value is always 1.
For a given triple, the position of all its possible triple patterns are incremented in the counters.
The current counter values for all those triple patterns are returned.

<figure id="algorithm-positions" class="algorithm">
````/algorithms/ingestion-positions.txt````
<figcaption markdown="block">
Algorithm for incrementally calculating the position of a deletion within a changeset.
</figcaption>
</figure>

[](#algorithm-ingestion-batch) contains the pseudocode of the batch ingestion algorithm.
It receives a changeset stream as input, and a reference to the current store.
The algorithm starts by reading the whole stream in-memory, sorting it in SPO order,
and encoding all triple components using the dictionary.
After that, it loads the previous changeset in memory,
which is required for merging it together with the new changeset using the algorithm from [](#algorithm-ingestion-batch-merge).
After that, we have the complete new changeset loaded in memory.
Now, we load each added triple into the addition trees, together with their version and local change flag.
After that, we can initiate deletion ingestion.
We start by iterating over all deleted triples in the new changeset
and calculating the position of the deletion using the algorithm from [](#algorithm-positions).
We can now ingest the given triple in the deletion trees with their version, local change flag and positions.

{:.todo}
Don't call your variable _new_ in the algorithm, was highly confused.
Also, changeset <-> changesetEncoded.

<figure id="algorithm-ingestion-batch" class="algorithm">
````/algorithms/ingestion-batch.txt````
<figcaption markdown="block">
In-memory batch ingestion algorithm
</figcaption>
</figure>

Even though this algorithm is straightforward,
it can require a large amount of memory for a number of reasons.
1) Loading the complete new changeset;
2) Loading the complete previous changeset;
3) Combining and loading the previous and new changesets;
4) Maintaining counters for the deletions in all possible triple patterns.
As deltas are stored relative to snapshots, their size can grow for an increasing number of versions,
which directly leads to larger memory requirements.
The theoretical time complexity of this algorithm is `O(P + N)`,
with `P` the number of triples in the previous changeset,
and `N` the number of triples in the new changeset.

#### Streaming Ingestion
{:#streaming-ingestion}

Because of the unbounded memory requirements of the [batch ingestion algorithm](#batch-ingestion),
we also introduce a more complex streaming ingestion algorithm.
It also takes a changeset stream and store as input parameters,
with as additional requirement on the stream that its contents must be sorted in SPO-order.
This is so that the algorithm can assume a consistent order and act as a sort-merge join operation.

In summary, the algorithm performs a sort-merge join over three streams in SPO-order:
1) the input changeset (N)
2) the existing deletions (D) over all versions
and 3) the existing additions (A) over all versions.
The algorithm iterates over all streams together, until all of them are finished.
The smallest triple over all stream heads is handled in each iteration,
and can be categorized in seven different cases:
<ol>
    <li>D &lt; N and D &lt; A</li>
    <li>A &lt; N and A &lt; D</li>
    <li>N &lt; A and N &lt; D</li>
    <li>N == D and N &lt; A</li>
    <li>N == A and N &lt; D</li>
    <li>A == D and A &lt; N</li>
    <li>A == D == N</li>
</ol>

The two first cases are the simplest ones,
for these, the deletion and addition information can respectively be copied to the new version.
For the deletion, new positions must be calculated in this and all other cases.
In the third case, a triple is added or removed that was not present before,
so it can either be added as a non-local change addition or a non-local change deletion.
In the fourth case, the new triple already existed as a deletion.
If the triple is an addition, it must be added as a local change.
If it is a deletion, it simply overwrites the existing deletion.
Similarly, in the fifth case the new triple already existed as an addition.
So the triple must be deleted as a local change if the new triple is a deletion.
It can be copied if it is an addition.
In the sixth case, the triple existed as both an addition and deletion at some point.
In this case, we copy over the one that existed at the latest version.
Finally, in the seventh case, the triple already existed as both an addition and deletion,
and is equal to our new triple.
This means that if the latest triple was an addition, it becomes a deletion, and the other way around,
and the local change flag can be inherited.

The theoretical memory requirement for this algorithm is much lower than the [batch variant](#batch-ingestion).
That is because instead of loading the complete new changeset in memory,
we now need to load at most three triples — the heads of each stream — in memory.
Furthermore, we still need to maintain the position counters for the deletions in all triple patterns.
While these counters could also become large, a smart implementation could perform memory-mapping
to avoid storing everything in memory.
The lower memory requirements comes at the cost of a higher logical complexity, but an equal time complexity.