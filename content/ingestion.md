## Ingestion
{:#ingestion}

In this section, we discuss an in-memory batch and a streaming ingestion algorithm.
These algorithms both take a changeset—containing additions and deletions—as input,
and ingest it to the store as a new version.
Note that the ingested changesets are regular changesets: they are relative to one another according to [](#regular-delta-chain).
Furthermore, we assume that the ingested changesets are valid changesets:
they don't contain impossible triple sequences such as a triple that is removed in two versions without having an addition in between.
During ingestion, they will be transformed to the alternative delta chain structure as shown in [](#alternative-delta-chain).
<span class="comment" data-author="RV">I think we should explain the necessity of such an ingestion algorithm. I.e., we could do it naively, just always delta with the snapshot, but this is better.</span>
Within the scope of this article, we only discuss ingestion of deltas in a single delta chain following a snapshot.

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

### Batch Ingestion
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

Because our querying algorithms require the position of each deletion within a changeset,
we introduce an algorithm for incrementally calculating this position in [](#algorithm-positions).
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

### Streaming Ingestion
{:#streaming-ingestion}

Because of the unbounded memory requirements of the [batch ingestion algorithm](#batch-ingestion),
we also introduce a more complex streaming ingestion algorithm.
It also takes a changeset stream and store as input parameters,
with as additional requirement on the stream that its contents must be sorted in SPO-order.
This is so that the algorithm can assume a consistent order and act as a sort-merge join operation.

In summary, the algorithm performs a sort-merge join over three streams in SPO-order:
1) the stream of _input_ changeset elements
2) the existing _deletions_ over all versions
and 3) the existing _additions_ over all versions.
The algorithm iterates over all streams together, until all of them are finished.
The smallest triple over all stream heads is handled in each iteration,
and can be categorized in seven different cases:

1. deletion < input _and_ deletion < addition
2. addition < input _and_ addition < deletion
3. input < addition _and_ input < deletion
4. input == deletion _and_ input < addition
5. input == addition _and_ input < deletion
6. addition == deletion _and_ addition < input
7. addition == deletion == input

The two first cases are the simplest ones, in which the current deletion and addition are respectively the smallest.
For these cases, the unchanged deletion and addition information can respectively be copied to the new version.
For the deletion, new positions must be calculated in this and all other cases.
In the third case, a triple is added or removed that was not present before,
so it can either be added as a non-local change addition or a non-local change deletion.
In the fourth case, the new triple already existed in the previous version as a deletion.
If the new triple is an addition, it must be added as a local change.
Similarly, in the fifth case the new triple already existed as an addition.
So the triple must be deleted as a local change if the new triple is a deletion.
In the sixth case, the triple existed as both an addition and deletion at some point.
In this case, we copy over the one that existed at the latest version, as it will still apply in the new version.
Finally, in the seventh case, the triple already existed as both an addition and deletion,
and is equal to our new triple.
This means that if the triple was an addition in the previous version, it becomes a deletion, and the other way around,
and the local change flag can be inherited.

The theoretical memory requirement for this algorithm is much lower than the [batch variant](#batch-ingestion).
That is because instead of loading the complete new changeset in memory,
we now need to load at most three triples — the heads of each stream — in memory.
Furthermore, we still need to maintain the position counters for the deletions in all triple patterns.
While these counters could also become large, a smart implementation could perform memory-mapping
to avoid storing everything in memory.
The lower memory requirements comes at the cost of a higher logical complexity, but an equal time complexity.
