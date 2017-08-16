## Querying
{:#querying}

In this section, we introduce algorithms for performing VM, DM and VQ triple pattern queries
based on the storage structure introduced in [](#storage).
Each of these querying algorithms is based on result streams, enabling offsets and limits.
Furthermore, querying algorithms typically use estimated counts for triple patterns in their optimizer algorithms,
such as [TPF](cite:cites ldf),
for determining the order of triple patterns during evaluation.
In order to support this, we provide corresponding count estimation queries.

### Version Materialization

#### Query

[](#algorithm-querying-vm) introduces an algorithm for VM triple pattern queries based on our storage structure.
It starts by determining the snapshot on which the given version is based.
After that, this snapshot is queried for the given triple pattern and offset.
If the given version is equal to the snapshot version, the snapshot iterator can be returned directly.
In all other cases, this snapshot offset is only an estimation,
and the actual snapshot offset can be larger if deletions were introduced before the actual offset.
Because of that, we enter a loop that will converge to the actual snapshot offset.
This loop starts by determining the triple at the current offset position in the snapshot.
We then query the deletions tree for the given triple pattern and version,
filter out local changes, and use the snapshot triple as offset.
This triple-based offset is done by navigating through the tree to the smallest triple before or equal to the offset triple.
If the query is not empty and the iterator has not yet ended,
we use the deletion's position for the current triple pattern as new snapshot offset.
If the query is not empty and the iterator has ended,
we use the total number of deletions without local changes for the given triple pattern in this version as offset.
Otherwise, if the deletion tree query has no results, we use zero as new snapshot offset.
From the moment the snapshot offset doesn't change anymore, we have converged to the correct offset.
After that, we return a simple iterator starting from that snapshot position,
which performs a sort-merge join-like operation that removes each triple from the snapshot that also appears in the deletion stream,
which can be done efficiently because of the consistent SPO-ordering.
Once the snapshot and deletion streams have finished,
the iterator will start emitting addition triples at the end of the stream.
For all streams, local changes are filtered out because local changes mean that
these triple are cancelled out for the given version as explained in [](#fundamentals),
so they should not be returned in materialized versions.

<figure id="algorithm-querying-vm" class="algorithm">
````/algorithms/querying-vm.txt````
<figcaption markdown="block">
Version Materialization algorithm for triple patterns that produces a triple stream with an offset in a given version.
</figcaption>
</figure>

The reason why we can use the deletion's position in the delta as offset in the snapshot
is because this position represents the number of deletions that came before that triple inside the snapshot given a consistent triple order.
[](#query-vm-example) shows simplified storage contents where triples are represented as a single letter,
and there is only a single snapshot and delta.
In the following paragraphs, we explain the offset convergence loop of the algorithm in function of this data for different offsets.

<figure id="query-vm-example" class="table" markdown="1">

| *Snapshot*  | A | B | C | D | E | F |
| ------------|---|---|---|---|---|---|
| *Deletions* |   | B |   | D | E |   |
| Positions   |   | 0 |   | 1 | 2 |   |

<figcaption markdown="block">
Simplified storage contents example where triples are represented as a single letter.
The snapshot contains six elements, and the next version contains three deletions.
Each deletion is annotated with its position.
</figcaption>
</figure>

#### Offset 0
For offset zero, the snapshot is first queried for this offset,
which results in a stream starting from `A`.
Next, the deletions are queried with offset `A`, which results in no match,
so the final snapshot stream starts from `A`.

#### Offset 1
For an offset of one, the snapshot stream initially starts from `B`.
After that, the deletions stream is offset to `B`, which results in a match.
The original offset (1), is increased with the position of `B` (0) and the constant 1,
which results in a new snapshot offset of 2.
We now apply this new snapshot offset.
As the snapshot offset has changed, we enter a second iteration of the loop.
Now, the head of the snapshot stream is `C`.
We offset the deletions stream to `C`, which again results in `B`.
As this offset results in the same snapshot offset,
we stop iterating and use the snapshot stream with offset 2 starting from `C`.

#### Offset 2
For offset 2, the snapshot stream initially starts from `C`.
After querying the deletions stream, we find `B`, with position 0.
We update the snapshot offset to 2 + 0 + 1 = 3,
which results in the snapshot stream with head `D`.
Querying the deletions stream results in `D` with position 1.
We now update the snapshot offset to 2 + 1 + 1 = 4, resulting in a stream with head `E`.
We query the deletions again, resulting in `E` with position 2.
Finally, we update the snapshot offset to 2 + 2 + 1 = 5 with stream head `F`.
Querying the deletions results in the same `E` element,
so we use this last offset in our final snapshot stream.

#### Estimated count

In order to provide an estimated count for VM triple pattern queries,
we introduce [](#algorithm-querying-vm-count).
This straightforward algorithm depends on the efficiency of the snapshot to provide count estimations for a given triple pattern.
Based on the snapshot count for the given triple pattern, the number of deletions for that version and triple pattern
are subtracted and the number of additions are added.
These last two can be resolved efficiently, as we precalculate
and store expensive addition and deletion counts as explained in [](#addition-counts) and [](#deletion-counts).

<figure id="algorithm-querying-vm-count" class="algorithm">
````/algorithms/querying-vm-count.txt````
<figcaption markdown="block">
Version Materialization count estimation algorithm for triple patterns in a given version.
</figcaption>
</figure>

#### Proof

In this section, we prove that the result of [](#algorithm-querying-vm) 
is a stream that correctly returns all triples for the given version, 
starting at the given offset.

##### _Algorithm description_
The first steps of the algorithm are initalization:
<ul>
<li markdown="1">
`snapshot`: the stream of triples from the snapshot on which the given version is based,
</li>
<li markdown="1">
`deletions`: the stream of triples that need to be deleted from `snapshot` for the given version,
</li>
<li markdown="1">
`additions`: the stream of triples that need to be appended to `snapshot` for the given version.
</li>
</ul>

During every iteration of the do/while loop,
we extract the triple in the snapshot at the current index
and count how many deletions are preceding that triple.
The original given offset then gets increased by that number of deletions.

`PatchedSnapshotIterator` returns all elements from the given snapshot stream,
except those present in the given deletions stream.
Afterwards all elements from the additions stream are appended.

##### _Proof_
If the given version is equal to the snapshot version the result is `snapshot`,
for the rest of the proof we assume the given version differs from the snapshot version.

There are 2 possible cases for the starting triple of the output stream:
 1. the triple is part of the snapshot stream, or,
 2. the triple is part of the additions stream.

A triple is in the first case if its index is smaller than `|snapshot|` - `|deletions|`,
and in the second situation if its index is equal or larger.
These 2 cases also correspond to the main `if`-statement in the algorithm.

In the first case we have to find the triple in the `snapshot` stream
for which the index in the version stream would be `originalOffset`.
The difference between the two streams, is that `snapshot` still contains all elements to be deleted for the current version.
Since the stream is sorted, the index of this triple in `snapshot` is
`originalOffset` + `offset`, with `offset` being the number of deletions
preceding that triple in `snapshot`.
Since the value of `offset` is the number of deletions preceding the given triple,
and the loop stops when we find the triple with the requested index,
the `snapshot` stream will be pointing to the correct element when the loop ends.
Since the value of `offset` can never decrease,
we are guaranteed for the loop to end.
Afterwards the output is a `PatchedSnapshotIterator` starting at the correct `snapshot` index,
appended with all additions, which is what we required.

In the second case the starting triple is in the stream of `additions`.
The number of elements preceding the `additions` elements, 
is the number of `snapshot` elements minus the `deletions`,
which is exactly what is calculated in the `else`-statement.
The `snapshot` stream is finalized by offsetting it after its last element,
which will cause the `PatchedSnapshotIterator` to only output `additions` elements
starting from the calculated index, which is also what we required.

### Delta Materialization

The goal of delta materialization queries is to query the triple differences between two versions.
Furthermore, each triple in the result stream is annotated with either being an addition or deletion between the given version range.
Within the scope of this work, we limit ourselves to delta materialization within a single snapshot and delta chain.
Because of this, we distinguish two different cases for our DM algorithm
in which we can query triple patterns between a start and end version,
the start version of the query can either correspond to the snapshot version or it can come after that.
Furthermore, we introduce an equivalent algorithm for estimating the number of results for these queries.

#### Query

For the first query case, where the start version corresponds to the snapshot version
the algorithm is straightforward.
Since we always store our deltas relative to the snapshot,
filtering the delta of the given end version based on the given triple pattern directly corresponds to the desired result stream.
Furthermore, we filter out local changes, as we are only interested in actual change with respect to the snapshot.

For the second case, the start version does not corresponds to the snapshot version.
The algorithm iterates over the triple pattern iteration scope of the addition and deletion trees in a sort-merge join-like operation,
and only emits the triples that have a different addition/deletion flag for the two versions.

#### Estimated count

For count esimation we can also distinguish the two separate cases from previous section.

For the first case, the start version corresponds to the snapshot version.
A query for counting the number of triples for the start version is delegated to the snapshot,
which we assume can happen efficiently.
After that, the number of deletions and additions for the given triple pattern and version are queried,
which can happen efficiently as described in [](#fundamentals).
The number of snapshot triples summed up with the number of deletions and additions is the resulting estimated number of results.

In the second case the start version does not correspond to the snapshot version.
We estimate the total count as the sum of the additions and deletions for the given triple pattern in both versions.
This may only be a rough estimate, but will always be an upper bound, as the triples that were changed twice within the version range and negate each other
are also counted.
For example, for querying within version 1 and 4, if triple A was added in version 2 but removed again in version 3,
it should not be included in the delta triple count with respect to version range `[1,4]`.
But according to our algorithm, this triple will be included twice in our counting, once as an addition and once as a deletion.
Our count in this case will at least be two too high.
For exact counting, this number of negated triples should be subtracted.

### Version Query

For the final query atom, version querying, we have to retrieve all triples across all versions,
annotated with the versions in which they exist.
In this work, we again focus on version queries for a single snapshot and delta chain.
For multiple snapshots and delta chains, the following algorithms should simply be applied once for each snapshot and delta chain.
In the following sections, we introduce an algorithm for performing triple pattern version queries
and an algorithm for estimating the total number of matching triples for the former queries.

#### Query

Our version querying algorithm is again based on a sort-merge join-like operation.

We start by iterating over the snapshot for the given triple pattern.
Each snapshot triple is queried within the deletion tree.
If such a deletion value can be found, the versions annotation contains all versions except for the versions
for which the given triple was deleted with respect to the given snapshot.
If no such deletion value was found, the triple has never been deleted,
so the versions annotation simply contains all versions of the store.
Result stream offsetting can happen efficiently if the snapshot allows efficient offsets.
When the snapshot iterator has finished, we iterate over the addition tree in a similar way.
Each addition triple is again queried within the deletions tree
and the versions annotation can equivalently be derived.

#### Estimated count

Calculating the number of triples matching any triple pattern version query is trivial.
We simply retrieve the count for the given triple pattern in the given snapshot
and add the number of additions for the given triple pattern over all versions.
The number of deletions should not be taking into account here,
as this information is only required for determining the version annotation in the version query results.
