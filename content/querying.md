## Querying
{:#querying}

In this section, we introduce algorithms for performing VM, DM and VQ triple pattern queries
based on the storage structure introduced in [](#storage).
Each of these querying algorithms is based on result streams, enabling offsets and limits.
Furthermore, querying algorithms typically use exact or estimated counts for triple patterns in their optimizer algorithms,
such as [TPF](cite:cites ldf),
for determining the order of triple patterns during evaluation.
In order to support this, we provide corresponding count estimation queries.

### Version Materialization

Version Materialization (VM) is the most straightforward versioned query type,
it allows you to query against a certain dataset version.
In the following, we start by introducing our VM querying algorithm,
after we give a simple example of this algorithm.
After that, we prove the correctness of our VM algorithm and introduce a corresponding algorithm to provide count estimation for VM query results.

#### Query

[](#algorithm-querying-vm) introduces an algorithm for VM triple pattern queries based on our storage structure.
On line 2, it starts by determining the snapshot on which the given version is based.
After that, this snapshot is queried for the given triple pattern and offset.
If the given version is equal to the snapshot version, the snapshot iterator can be returned directly (line 3).
In all other cases, this snapshot offset could only be an estimation,
and the actual snapshot offset can be larger if deletions were introduced before the actual offset.

Our algorithm returns a stream where triples originating from the snapshot always
come before the triples that were added in later additions.
Because of that, the mechanism for determining the correct offset in the
snapshot, additions and deletions streams can be split up into two cases.
The given offset lies within the range of either snapshot minus deletion triples or within the range of addition triples.
At this point, the additions and deletions streams are initialized to the start position for the given triple pattern and version.

In the first case, when the offset lies within the snapshot and deletions range, i.e., line 11,
we enter a loop that converges to the actual snapshot offset based on the deletions
for the given triple pattern in the given version.
This loop starts by determining the triple at the current offset position in the snapshot (line 13, 14).
On line 15, we then query the deletions tree for the given triple pattern and version,
filter out local changes, and use the snapshot triple as offset.
This triple-based offset is done by navigating through the tree to the smallest triple before or equal to the offset triple.
We store an additional offset value (line 16), which corresponds to the current numerical offset inside the deletions stream.
As long as the current snapshot offset is different from the sum of the original offset and the additional offset,
we continue iterating this loop (line 17), which will continuously update this additional offset value.

In the second case, i.e., line 19, the given offset lies within the additions range.
Now, we terminate the snapshot stream by offsetting it after its last element on line 20,
and we relatively offset the additions stream on line 21.
This offset is calculated as the original offset subtracted with the number of snapshot triples incremented with the number of deletions.

Finally, on line 24, we return a simple iterator starting from the three streams that could be offset.
This iterator performs a sort-merge join operation that removes each triple from the snapshot that also appears in the deletion stream,
which can be done efficiently because of the consistent SPO-ordering.
Once the snapshot and deletion streams have finished,
the iterator will start emitting addition triples at the end of the stream.
For all streams, local changes are filtered out because locally changed triples
are cancelled out for the given version as explained in [](#fundamentals),
so they should not be returned in materialized versions.

<figure id="algorithm-querying-vm" class="algorithm numbered">
````/algorithms/querying-vm.txt````
<figcaption markdown="block">
Version Materialization algorithm for triple patterns that produces a triple stream with an offset in a given version.
</figcaption>
</figure>

#### Example

We can use the deletion's position in the delta as offset in the snapshot
because this position represents the number of deletions that came before that triple inside the snapshot given a consistent triple order.
[](#query-vm-example) shows simplified storage contents where triples are represented as a single letter,
and there is only a single snapshot and delta.
In the following paragraphs, we explain the offset convergence loop of the algorithm in function of this data for different offsets.

<figure id="query-vm-example" class="table" markdown="1">

| Snapshot    | A | B | C | D | E | F |
| ------------|---|---|---|---|---|---|
| Deletions   |   | B |   | D | E |   |
| Positions   |   | 0 |   | 1 | 2 |   |

<figcaption markdown="block">
Simplified storage contents example where triples are represented as a single letter.
The snapshot contains six elements, and the next version contains three deletions.
Each deletion is annotated with its position.
</figcaption>
</figure>

##### _Offset 0_
For offset zero, the snapshot is first queried for this offset,
which results in a stream starting from `A`.
Next, the deletions are queried with offset `A`, which results in no match,
so the final snapshot stream starts from `A`.

##### _Offset 1_
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

##### _Offset 2_
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
we introduce a straightforward algorithm that depends on the efficiency of the snapshot to provide count estimations for a given triple pattern.
Based on the snapshot count for a given triple pattern, the number of deletions for that version and triple pattern
are subtracted and the number of additions are added.
These last two can be resolved efficiently, as we precalculate
and store expensive addition and deletion counts as explained in [](#addition-counts) and [](#deletion-counts).

#### Correctness

In this section, we prove that [](#algorithm-querying-vm) results in the correct stream offset
for any given version and triple pattern.

##### _Algorithm description_
The algorithm is initialized as follows:

* `snapshot`: stream of triples from the snapshot with largest version ID less than or equal to the given version,
* `deletions`: stream of triples that are deleted from `snapshot` for the given version,
* `additions`: stream of triples that are added to `snapshot` for the given version.
* `offset`: The extra snapshot offset to take into account the `deletions` that need to be removed from `snapshot`, initialized as `0`.

During every iteration of the do/while loop,
we determine the triple in the snapshot at the index (`originalOffset + offset`),
and count how many deletions are preceding that triple for the given triple pattern (i.e., the relative position).
`offset` is then set to that number of deletions.

When the do/while loop terminates,
`PatchedSnapshotIterator` returns all elements from the given snapshot stream,
minus the deletions, followed by the additions.

##### _Proof_
Two cases can occur with regards to the version:

1. the version is equal to the snapshot version,
2. the version is strictly larger than the snapshot version.

In the first case (line 3), the output stream is the `snapshot` stream.
For the remainder of this proof, we will elaborate on the second case.

The first triple in the output stream can originate from either the snapshot stream or the additions stream.
A triple originates from the snapshot stream if its index within the stream is smaller than `|snapshot|` − `|deletions|` (line 11),
otherwise, it originates from the additions stream (line 19).

In the first case (line 11) we have to find the triple in the `snapshot` stream
for which the index in the output stream would be `originalOffset`.
The difference between the two streams, is that `snapshot` still contains all elements to be deleted for the current version.
Since the stream is sorted, the index of this triple in `snapshot` is
`originalOffset` + `offset` (line 13), with `offset` being the number of deletions
preceding that triple in `snapshot`.
The do/while loop iteratively determines this triple by (absolutely) offsetting the `snapshot` stream (line 13),
and updates the value of `offset` (line 16).
The loop only terminates when no new deletions were found since last iteration (line 17),
and since the value of `offset` can never decrease,
the loop is guaranteed to end.
At this point, the head of the snapshot stream is now correctly pointing at the snapshot element at `originalOffset` with `offset` deletions preceding it.
Afterwards the output is a `PatchedSnapshotIterator` starting at the correct `snapshot` index,
minus the deletions (line 24),
appended with all additions, which is what we required.

In the second case (line 19) the starting triple is in the stream of `additions`.
The number of elements preceding the `additions` elements,
is the number of `snapshot` elements minus the number of `deletions`,
which is exactly what is calculated on line 21.
The `snapshot` stream is finalized by offsetting it after its last element (line 20),
which will cause the `PatchedSnapshotIterator` to only output `additions` elements
starting from the calculated index, which is also what we required.

### Delta Materialization

The goal of delta materialization (DM) queries is to query the triple differences between two versions.
Furthermore, each triple in the result stream is annotated with either being an addition or deletion between the given version range.
Within the scope of this work, we limit ourselves to delta materialization within a single snapshot and delta chain.
Because of this, we distinguish between two different cases for our DM algorithm
in which we can query triple patterns between a start and end version,
the start version of the query can either correspond to the snapshot version or it can come after that.
Furthermore, we introduce an equivalent algorithm for estimating the number of results for these queries.

#### Query

For the first query case, where the start version corresponds to the snapshot version,
the algorithm is straightforward.
Since we always store our deltas relative to the snapshot,
filtering the delta of the given end version based on the given triple pattern directly corresponds to the desired result stream.
Furthermore, we filter out local changes, as we are only interested in actual change with respect to the snapshot.

For the second case, the start version does not correspond to the snapshot version.
The algorithm iterates over the triple pattern iteration scope of the addition and deletion trees in a sort-merge join-like operation,
and only emits the triples that have a different addition/deletion flag for the two versions.

#### Estimated count

For count esimation we can also distinguish the two separate cases from previous section.

For the first case, the start version corresponds to the snapshot version.
A query for counting the number of triples for the start version is delegated to the snapshot,
which we assume can happen efficiently.
After that, the number of deletions and additions for the given triple pattern and version are queried,
which can happen efficiently as described in [](#fundamentals).
The estimated number of results is then the number of snapshot triples summed up with the number of deletions and additions.

In the second case the start version does not correspond to the snapshot version.
We estimate the total count as the sum of the additions and deletions for the given triple pattern in both versions.
This may only be a rough estimate, but will always be an upper bound, as the triples that were changed twice within the version range and negate each other
are also counted.
For example, for querying within version 1 and 4, if triple A was added in version 2 but removed again in version 3,
it should not be included in the delta triple count with respect to version range `[1,4]`.
But according to our algorithm, this triple will be included twice in our counting, once as an addition and once as a deletion.
Our count in this case will at least be 2 too much.
For exact counting, this number of negated triples should be subtracted.

### Version Query

For version querying (VQ), the final query atom, we have to retrieve all triples across all versions,
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
If no such deletion value was found, the triple was never deleted,
so the versions annotation simply contains all versions of the store.
Result stream offsetting can happen efficiently as long as the snapshot allows efficient offsets.
When the snapshot iterator is finished, we iterate over the addition tree in a similar way.
Each addition triple is again queried within the deletions tree
and the versions annotation can equivalently be derived.

#### Estimated count

Calculating the number of unique triples matching any triple pattern version query is trivial.
We simply retrieve the count for the given triple pattern in the given snapshot
and add the number of additions for the given triple pattern over all versions.
The number of deletions should not be taken into account here,
as this information is only required for determining the version annotation in the version query results.
