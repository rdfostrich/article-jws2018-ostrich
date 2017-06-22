## Querying
{:#querying}

In this section, we introduce algorithms for performing VM, DM and VQ triple pattern queries
based on the storage structure introduced in [](#storage).
Each of these querying algorithms is based on result streams, enabling efficient offsets and limits.
Furthermore, we introduce corresponding count estimation queries,
which can help external systems for query optimization for multiple triple patterns.

{:.todo}
Say that we don't need OPS because P and O can be switched to use POS. We don't care about order, maybe Hexastore and RDF-3X do.

{:.todo}
Explain different triple component orders and show (prove?) that they are sufficient for all triple patterns.

{:.todo}
Local changes

{:.todo}
Offsets based on position metadata

### Version Materialization

#### Query

[](#algorithm-querying-vm) introduces an algorithm for VM triple pattern queries based on our storage structure.
It starts by determining the snapshot on which the given version is based on.
After that, this snapshot is queried for the given triple pattern and offset.
If the given version is equal to the snapshot version, the snapshot iterator can be returned directly.
In all other cases, this snapshot offset is only an estimation,
and the actual snapshot offset can be larger if deletions were introduced before the actual offset.
Because of that, we enter a loop that will converge to the actual snapshot offset.
This loop starts by determining the triple at the current offset position in the snapshot.
We then query the deletions tree with for the given triple pattern and version,
and use the snapshot triple as offset.
This triple-based offset is done by navigating through the tree to the smallest triple before or equal to the offset triple.
If the query is not empty and the iterator has not yet ended,
then we use the deletion's position for the current triple pattern as new snapshot offset.
If the query is not empty and the iterator has ended,
we use the total number of deletions for the given triple pattern in this version as offset.
Otherwise, if the deletion tree query has no results, we use zero as new snapshot offset.
From the moment that the snapshot offset doesn't change anymore, we have converged to the correct offset.
After that, we return a simple iterator starting from that snapshot position,
which performs a sort-merge join-like operation that removes each triple from the snapshot that also appears in the deletion stream,
which can be done efficiently because of the consistent SPO-ordering.
From the moment the snapshot and deletion streams have finished,
the iterator will start emitting addition triples at the end of the stream.

<figure id="algorithm-querying-vm" class="algorithm">
````/algorithms/querying-vm.txt````
<figcaption markdown="block">
Version Materialization algorithm for triple patterns that produces a triple stream with an offset.
</figcaption>
</figure>

The reason why we can use the deletion's position in the changeset as offset in the snapshot
is because this position represents the number of deletions that came before that triple inside the snapshot given a consistent triple order.

[](#query-vm-example) shows simplified storage contents where triples are represented as a single letter,
and there is only a single snapshot and delta.
In the following paragraphs, we explain the offset convergence loop of the algorithm in function of this data for different offsets.

<figure id="query-vm-example" class="algorithm">
<img src="img/query-vm-example.svg" alt="[query vm example]" height="70em">
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

#### Proof

{:.todo} proof

#### Estimated count

{:.todo}
count

### Delta Materialization

{:.todo}
Write algo+count

### Version Query

{:.todo}
Write algo+count
