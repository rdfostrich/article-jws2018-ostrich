## Ingestion
{:#ingestions}

In this section, we discuss two ingestion algorithms: a memory-intensive batch algorithm and a memory-efficient streaming algorithm.
These algorithms both take a changeset—containing additions and deletions—as input,
and append it as a new version to the store.
Note that the ingested changesets are regular changesets: they are relative to one another according to [](#regular-delta-chain).
Furthermore, we assume that the ingested changesets are valid changesets:
they don't contain impossible triple sequences such as a triple that is removed in two versions without having an addition in between.
During ingestion, they will be transformed to the alternative delta chain structure as shown in [](#alternative-delta-chain).
Within the scope of this article, we only discuss ingestion of deltas in a single delta chain following a snapshot.

Next to ingesting the added and removed triples,
an ingestion algorithm for our storage approach must be able to calculate
the appropriate metadata for the store as discussed in [](#delta-storage).
More specifically, an ingestion algorithm has the following requirements:
<ul>
    <li>addition triples must be stored in all addition trees;</li>
    <li>additions and deletions must be annotated with their version;</li>
    <li>additions and deletions must be annotated with being a local change or not;</li>
    <li>deletions must be annotated with their position for all triple patterns.</li>
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
First, all contents of the original changeset are copied into the new changeset (line 3).
After that, we iterate over all triples of the second changeset (line 4).
If the changeset already contained the given triple (line 5), the local change flag is negated.
Otherwise, the triple is added to the new changeset, and the local change flag is set to `false` (line 8-10).
Finally, in both cases the addition flag of the triple in the new changeset is copied from the second changeset (line 12).

<figure id="algorithm-ingestion-batch-merge" class="algorithm numbered">
````/algorithms/ingestion-batch-merge.txt````
<figcaption markdown="block">
In-memory changeset merging algorithm
</figcaption>
</figure>

Because our querying algorithms require the relative position of each deletion within a changeset to be stored,
we have to calculate these positions during ingestion.
We do this using the helper function `calculatePositions(triple)`.
This function depends on external mappings that persist over the duration of the ingestion phase
that map from triple to a counter for each possible triple pattern.
When this helper function is called for a certain triple,
we increment the counters for the seven possible triple patterns of the triple.
For the triple itself, we do not maintain a counter, as its value is always 1.
Finally, the function returns a mapping for the current counter values of the seven triple patterns.

The batch ingestion algorithm starts by reading a complete changeset stream in-memory, sorting it in SPO order,
and encoding all triple components using the dictionary.
After that, it loads the changeset from the previous version in memory,
which is required for merging it together with the new changeset using the algorithm from [](#algorithm-ingestion-batch-merge).
After that, we have the new changeset loaded in memory.
Now, we load each added triple into the addition trees, together with their version and local change flag.
After that, we finally load each deleted triple into the deletion trees
with their version, local change flag and positions.
These positions are calculated using `calculatePositions(triple)`.
For the sake of completeness, we included the algorithm in pseudo-code in [Appendix A](#appendix-algorithms).

Even though this algorithm is straightforward,
it can require a large amount of memory for a number of reasons:
1) loading the complete new changeset;
2) loading the complete previous changeset;
3) combining and loading the previous and new changesets;
4) maintaining counters for the deletions in all possible triple patterns.
As deltas are stored relative to snapshots, their size can grow for an increasing number of versions,
which directly leads to larger memory requirements.
The theoretical time complexity of this algorithm is `O(P + N log(N))` (`O(P + N)` if the new changeset is already sorted),
with `P` the number of triples in the previous changeset,
and `N` the number of triples in the new changeset.

### Streaming Ingestion
{:#streaming-ingestion}

Because of the unbounded memory requirements of the [batch ingestion algorithm](#batch-ingestion),
we introduce a more complex streaming ingestion algorithm.
Just like the batch algorithm, it takes a changeset stream and store as input parameters,
with the additional requirement that the stream's values must be sorted in SPO-order.
This way the algorithm can assume a consistent order and act as a sort-merge join operation.
Just as for the batch algorithm, we included this algorithm in pseudo-code in [Appendix A](#appendix-algorithms).

In summary, the algorithm performs a sort-merge join over three streams in SPO-order:
1) the stream of _input_ changeset elements that are encoded using the dictionary when each element is read,
2) the existing _deletions_ over all versions
and 3) the existing _additions_ over all versions.
The algorithm iterates over all streams together, until all of them are finished.
The smallest triple (string-based) over all stream heads is handled in each iteration,
and can be categorized in seven different cases:

1. deletion < input _and_ deletion < addition
2. addition < input _and_ addition < deletion
3. input < addition _and_ input < deletion
4. input == deletion _and_ input < addition
5. input == addition _and_ input < deletion
6. addition == deletion _and_ addition < input
7. addition == deletion == input

<div style="color:red">Miel: I would merge the explanation below with the 7-item list in one description list.</div>

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
That is because load at most three triples, i.e., the heads of each stream, in memory, instead of the complete new changeset.
Furthermore, we still need to maintain the position counters for the deletions in all triple patterns.
While these counters could also become large, a smart implementation could perform memory-mapping
to avoid storing everything in memory.
The lower memory requirements come at the cost of a higher logical complexity, but an equal time complexity (assuming sorted changesets).
