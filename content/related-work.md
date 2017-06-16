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
HDT archives are read-only, which leads to its high compressability,
but makes it unsuitable for cases where datasets change frequently,
as HDT files should be regenerated completely.


### RDF Archiving
{:#related-work-archiving}

{:.todo}
[SemVersion](cite:cites semversion) (Combust deliverable)

{:.todo}
[Version Control for RDF Triple Stores](cite:cites vcrdf) (Combust deliverable)

{:.todo}
[A version management framework for RDF triple stores](cite:cites vmrdf) (Combust deliverable)

{:.todo}
[R&WBase](cite:cites rwbase) (Combust deliverable)

{:.todo}
[R43ples](cite:cites r43ples) (Combust deliverable)

{:.todo}
[Scalable Semantic Version Control for Linked Data Management](cite:cites vcld) (Combust deliverable)

{:.todo}
[X-RDF-3X](cite:cites xrdf3x) (Combust deliverable)

{:.todo}
[TailR](cite:cites tailr) (Combust deliverable)

{:.todo}
[Self-indexing RDF archives](cite:cites selfindexingarchives)

{:.todo}
[Self-indexing RDF archives](cite:cites selfindexingarchives)

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