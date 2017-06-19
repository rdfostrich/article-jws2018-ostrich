## Related Work
{:#related-work}

### RDF Indexing and Compression

RDF storage systems typically use indexing and compression techniques
for respectively reducing query times and storage requirements.
These systems can either be based on existing database technologies,
such as [relational databases](cite:cites virtuoso) or [document stores](cite:cites dsparq),
or are based on techniques tailored to RDF.
For the remainder of this article, we focus on the latter.

[RDF-3X](cite:cites rdf3x) is an RDF storage technique that is based
on a clustered B+Tree with 18 indexes in which triples are sorted lexicographically.
6 indexes exist for each possible triple component order (SPO, SOP, OSP, OPS, PSO and POS),
6 aggregated indexes (SP, SO, PS, PO, OS, and OP)
and 3 one-valued indexes (S, P, and O).
A dictionary is used to compress common triple components.
When evaluating SPARQL queries, the optimal indexes can be selected based on the query's triple patterns.
Furthermore, the store allows update operations.

[Hexastore](cite:cites hexastore) is similar in the sense that it uses six different B+Trees,
one for each possible triple component order.
It also uses dictionary encoding to compress common triple components.

[Triplebit](cite:cites triplebit) is an alternative approach that is based on a two-dimensional storage matrix.
The columns correspond to predicates, and the subjects and objects correspond to rows.
This sparse matrix is compressed and dictionary encoded to reduce storage requirements significantly.
Furthermore, its uses auxiliary index structures to improve index selection during query evaluation.

[HDT](cite:cites hdt) is a binary RDF representation that is highly compressed
and provides indexing structures that enable efficient querying.
It consists of 3 main components:
<ul>
    <li>Header: Metadata describing the dataset.</li>
    <li>Dictionary: Mapping between triple components and unique IDs for reducing storage requirements of triples.</li>
    <li>Triples: Storage of the actual triples based on the IDs of the triple components.</li>
</ul>
HDT archives are read-only, which leads to its high compressability,
but makes it unsuitable for cases where datasets change frequently,
as HDT files should be regenerated completely.
Its fast triple pattern queries and high compression rate make it
the go-to backend storage method for [TPF](cite:cites ldf) servers.
Approaches like [LOD Laundromat](lodlaundromat) combine HDT and TPF for hosting and publishing
650K+ Linked Datasets containing 38M+ triples, proving its usefulness at large scale.

### RDF Archiving
{:#related-work-archiving}

{:.todo}
Add rough evaluation results to each part, to motivate the choice on what to compare with (BEAR).

As Linked Open Datasets typically [change over time](cite:cites datasetdynamics)
and there is a need for [maintaining the history of the datasets](cite:cites archiving),
RDF archiving has been an active area of research over the last couple of years.

[SemVersion](cite:cites semversion) was one of the first works to look into tracking different versions of RDF graphs.
SemVersion is based on Concurrent Versions System (CVS) concepts to maintain different versions of ontologies,
such as diff, branching and merging
Their approach consists of a separation of language-specific features with ontology versioning from general features with RDF versioning.
The authors omit implementation details on triple storage and retrieval.

Based on the Theory of Patches from [Darcs software management system](darcs),
[Cassidy et. al.](cite:cites vcrdf) propose to store graph changes as a series of patches.
In the paper, they describe operations on versioned graphs such as reverse, revert and merge.
They provide an implementation of their approach using the Redland python library and MySQL
by representing each patch as named graphs and serializing them as TriG.
Furthermore, a preliminary evaluation shows that their implementation is significantly slower
than a native RDF store. They suggest a native implementation of the approach to avoid some of the overhead.

[Im et. al.](cite:cites vmrdf) propose a patching system based on a relational database.
In their approach, they use a storage scheme called *aggregated deltas*
which associates the latest version with each of the previous ones.
While aggregated deltas result in fast delta queries, they introduce a lot of storage overhead.

[R&WBase](cite:cites rwbase) is a versioning system that adds an additional versioning layer to existing quad-stores.
It adds the functionality of tagging, branching and merging for datasets.
The graph element is used to represent the additions and deletions of patches,
which are respectively the even and uneven graph id's.
Queries are resolved by looking at the highest even graph number of triples.

Graube et. al. introduce [R43ples](cite:cites r43ples) which stores changesets as separate named graphs.
It supports the same versioning features as R&WBase and introduces new SPARQL keywords for these, such as REVISION, BRANCH and TAG.
As reconstructing a version requires combining all changesets that came before,
queries at a certain version are only usable for medium-sized datasets.

[Hauptman et. al. introduce a similar delta-based storage approach](cite:cites vcld)
by storing each triple in a different named graph.
The identifying graph of each triple is used in a commit graph for SPARQL query evaluation at a certain version.
Their implementation is based on Sesame and Blazegraph and is slower than snapshot-based approaches, but uses less disk space.

[X-RDF-3X](cite:cites xrdf3x) is an extension of [RDF-3X](cite:cites rdf3x) which adds versioning support.
On storage-level, each triple is annotated with a creation and deletion timestamp.
This enables time-travel queries where only triples valid at the given time are returned.

[TailR](cite:cites tailr) is an HTTP archive for Linked Data pages based
on the [Memento](cite:cites memento) for retrieving prior versions of certain URIs.
It starts by storing a dataset snapshot, after which only deltas are stored for each consecutive version.
When delta chains become long, a new snapshot is created to avoid long version reconstruction times.
This approach requires more storage space than pure delta-based approaches,
but comes with the benefit of faster version reconstruction for many versions.
Their implementation is based on a relation database system.
Evaluation shows that resource lookup times for any version ranges between
1 and 50 ms for 10 versions containing around 500K triples.
In total, these versions require ~64MB of storage space.

[v-RDFCSA](cite:cites selfindexingarchives) is a self-indexing RDF archive mechanism,
based on the RDF self-index [RDFCSA](cite:cites rdfcsa),
that enables versioning queries on top of compressed RDF archives.
They evaluate their approach using the [BEAR](cite:cites bear) benchmark
and show that they can reduce storage space requirements 60 times compared to raw storage.
Furthermore, they reduce query evaluation times more than an order of magnitude compared to state of the art solutions.

[Dydra](cite:cites dydra) is an RDF graph storage platform with dataset versioning support.
They introduce the REVISION keyword, which is similar to the GRAPH SPARQL keyword for referring to different dataset versions.
Their implementation is based on B+Trees that are indexed in six ways  GSPO, GPOS, GOSP, SPOG, POSG, OSPG.
Each B+Tree value indicates the revisions in which a particular quad exists.

### RDF Archive Querying

{:.todo}
[diachron](cite:cites diachronql), [T-SPARQL](cite:cites tsparql), [SPARQL-ST](cite:cites sparqlst)

### Other

{:.todo}
Remove this section and fit these paragraphs in somewhere else.

[Memento](cite:cites memento) is an HTTP framework that enables time-based access to HTTP resources.
It does this by providing datetime content-negotiation for HTTP resources.
With this, users can access past versions of resources.

[Git](cite:cites git) is a distributed version control system, which is typically used in software development projects.
Git enables users to work of text documents independently, and synchronize their versions safely.
Furthermore, it maintains a complete history of the documents by storing the differences between each version.

### RDF Archiving Benchmarks

{:.todo}
[BEAR](cite:cites bear)

{:.todo}
EvoGen