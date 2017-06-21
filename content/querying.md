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
If the deletion tree query is not empty, then we use the deletion's position for the current triple pattern as new snapshot offset.
Otherwise, we use the total number of deletions for the given triple pattern in this version as offset.
From the moment that the snapshot offset doesn't change anymore, we have converged to the correct offset.
After that, we return a simple iterator starting from that snapshot position,
which performs a sort-merge join-like operation that removes each triple from the snapshot that also appears in the deletion stream,
which can be done efficiently because of the consistent SPO-ordering.
From the moment the snapshot and deletion streams have finished,
the iterator will start emitting addition triples at the end of the stream.

The reason why we can use the deletion's position in the changeset as offset in the snapshot
is because this position represents the number of deletions that came before that triple inside the snapshot given a consistent triple order.

{:.todo} proof

{:.todo} give a visual example on how offset convergence works?

<figure id="algorithm-querying-vm" class="algorithm">
````/algorithms/querying-vm.txt````
<figcaption markdown="block">
Version Materialization algorithm for triple patterns that produces a triple stream with an offset.
</figcaption>
</figure>

{:.todo}
count

### Delta Materialization

{:.todo}
Write algo+count

### Version Query

{:.todo}
Write algo+count
