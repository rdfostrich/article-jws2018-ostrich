## Storage
{:#storage}

In this section, we introduce our hybrid IC/CB/TB storage approach for storing multiple versions of an RDF dataset.
[](#storage-overview) shows an overview of the main components.
Our approach consists of an initial dataset snapshot---stored in [HDT](cite:cites hdt)---followed by a delta chain [](cite:cites tailr).
The delta chain uses multiple compressed B+Trees for a TB-storage strategy [](cite:cites dydra),
applies dictionary-encoding to triples, and
stores additional metadata to improve lookup times [](cite:cites hdt),
We discuss each component in more detail,
and describe two ingestion algorithms: a memory-intensive batch algorithm and a memory-efficient streaming algorithm.

<figure id="storage-overview">
<img src="img/storage-overview.svg" alt="[storage overview]">
<figcaption markdown="block">
First, metadata about the complete archive is stored, containing information such as the total number of available versions.
Furthermore, the very first version of a delta chain is stored as a _fully materialized snapshot_, for example using the HDT format.
Each following version in the chain is stored as a _delta_ relative to the initial snapshot.
All delta's are compressed in _addition and deletion trees_, where a _dictionary_ is used to compress triple components.
Finally, we store the _counts_ for certain triple pattern queries over _additions_ for each version.
</figcaption>
</figure>

### Snapshot storage
{:#snapshot-storage}

As mention before, the start of each delta chain is a fully materialized snapshot.
In order to provide sufficient efficiency for VM, DM and VQ querying with respect to all versions in the chain,
we assume the following requirements for the snapshot storage:

- Any triple pattern query _must_ be resolvable as triple streams.
- Offsets _must_ be applicable to the result stream of any triple pattern query.
- All triple components _must_ be dictionary-encoded.
- Cardinality estimation for all triple pattern queries _must_ be possible.

These requirements are needed for ensuring the efficiency of the querying algorithms that will be introduced in [](#querying).
Providing an implementation for a snapshot store is out of scope for this work,
but existing techniques such as [HDT](cite:cites hdt) fulfill all these requirements.
As such, HDT will be used in our implementation, which will be explained further in [](#implementation).

### Delta Storage
{:#delta-storage}

In order to cope with the newly introduced redundancies in our delta chain structure,
we introduce a delta storage method similar to the TB storage strategy,
which is able to compress redundancies within consecutive deltas.
Instead of storing timestamped triples, as is done in a regular TB approach,
we store timestamped triples annotated with addition or deletion.

The additions and deletions of deltas require different metadata in our querying algorithms,
which will be explained in [](#querying).
Additions and deletions are stored in separate stores,
which hold all additions and deletions from the complete delta chain.
Each store uses a B+Tree data structure,
where a key corresponds to a triple and the value contains version information.
The version information consists of a mapping from version to a local change flag and, in case of deletions, also the relative position of the triple inside the delta.
Even though triples can exist in multiple deltas in the same chain,
they will only be stored once.
Each addition and deletion store uses three trees with a different triple component order (SPO, POS and OSP),
which is sufficient for optimally resolving any triple pattern (as discussed in [](#indexes)).

The local change flag indicates whether or not the triple is a _local change_, which, as mentioned in [](#local-changes), further improves query evaluation time.
A triple is a local change in a certain version if it was already either added or removed in an earlier version.
This local change information helps the querying algorithm to determine when to ignore a triple or not.

The relative position of each triple inside the delta to the deletion trees speeds up the process of patching a snapshot's triple pattern subset for any given offset.
This position information has two purposes:
1) it allows the querying algorithm to exploit offset capabilities of the snapshot store
to resolve offsets for any triple pattern against any version;
and 2) it allows deletion counts for any triple pattern and version to be determined efficiently.

The use of the relative position and the local change flag will be further explained in [](#querying).

### Delta Chain Dictionary
{:#dictionary}

A common technique in [RDF indexes](cite:cites hdt,rdf3x,triplebit) is using a dictionary for mapping triple components to numerical IDs.
This is done for three main reasons:
1) reduce storage space if triple components are stored multiple times;
2) reducing I/O overhead when retrieving data;
2) simplify and optimize querying.
As our storage approach essentially stores each triple three or six times,
a dictionary can definitely reduce storage space requirements.

Each delta chain consists of two dictionaries, one for the snapshot and one for the deltas.
The snapshot dictionary can be optimized and sorted, as it will not change over time.
The delta dictionary is volatile, as each new version can introduce new mappings.

During triple encoding, the snapshot dictionary will always first be probed for existence of the triple component.
If there is a match, that ID is used for storing the delta's triple component.
To identify the appropriate dictionary for triple decoding,
some form of dictionary identification is encoded inside the ID, e.g., with a reserved bit.
The text-based dictionary entries can be compressed to reduce storage space further, as they are likely to contain a lot of redundancies.

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
{:#deletion-counts}

As mentioned in [](#delta-storage), each deletion is annotated with its relative position in all deletions for that version.
This position is exploited to perform deletion counting for any triple pattern and version.
We lookup the largest possible triple for the given triple pattern in the deletions tree,
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
