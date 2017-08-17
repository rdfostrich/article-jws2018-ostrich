## Introduction
{:#introduction}

In the area of data analysis,
there is an ongoing need for maintaining the history of datasets.
Motivations vary between looking up data at certain points in time,
requesting evolving changes,
or querying for the temporal validity of these data.
With the continuously increasing number of [Linked Open Datasets](cite:cites linkeddata),
this is an apparent issue for [RDF](cite:cites spec:rdf) data as well.
RDF allows the formation of directed, labeled graphs of IRIs and literals, which makes it a common format to store Linked Data.
These graphs are represented with _triples_, in which a subject is linked via a predicate to an object.
When these triples are declared in named _graphs_, we can refer to them as _quads_, i.e., triples with a fourth graph element.
While the RDF data model is atemporal, Linked Datasets typically [change over time](cite:cites datasetdynamics) on
[dataset, schema and/or instance level](cite:cites diachronql). These refer to additions,
changes or deletions of respectively complete datasets, ontologies and separate facts.
While some evolving datasets, such as [DBpedia](dbpedia),
are published as separate dumps per version,
efficient access to prior versions is often limited.

A [survey on archiving Linked Open Data](cite:cites archiving) illustrated the need for improved versioning capabilities,
as current RDF archiving approaches have scalability issues at Web-scale.
Existing RDF archiving solutions either perform well for versioned query evaluation at the cost of large storage space requirements,
or they require less storage space at the cost of slower query evaluation.
Furthermore, no existing solution performs well for all versioned query types, i.e., querying *at*, *between* and *for* different versions.
The authors of this survey state that an efficient RDF archive solution should have a scalable *storage model*,
efficient *compression* and *indexing methods* that should enable expressive versioned querying.
The performance of existing solutions in each of these areas is limited and should be improved.

Versioning also is a popular area in other domains, such as software development.
[Git](cite:cites git) is a distributed version control system, typically used in software development projects,
which enables users to work of text documents independently, and synchronize their versions safely.
Furthermore, it maintains a complete history of the documents by storing the *differences* between each version.
Storing the differences, i.e. changesets/deltas, between each version instead of maintaining fully materialized snapshots of each version
can significantly reduce the storage requirements for archives.
Techniques like these are also used in existing RDF archiving solutions.

Many existing RDF archiving techniques allow the full expressivity of [SPARQL queries](cite:cites spec:sparqllang).
SPARQL engines are typically used as a way to expose Web-access though [SPARQL endpoints](cite:cites spec:sparqlprot)
to RDF datasets, or in this case, RDF archives.
In practise, public SPARQL endpoints do however suffer from a [low availability](cite:cites sparqlwebquerying).
The [unbounded complexity of SPARQL queries](cite:cites sparqlcomplexity) combined
with SPARQL endpoints being public requires a high server cost,
which makes it expensive to host such an interface with high availability.
As an alternative, low-cost interfaces such as the [Triple Pattern Fragments](cite:cites ldf) (TPF) can be used for publishing RDF datasets on the Web.
TPF servers expose a REST interface that accepts paged triple pattern queries,
with which clients can evaluate full SPARQL queries client-side.
This technique proves to lower server load when compared to traditional SPARQL endpoints.

By itself, the TPF interface is, just like the RDF data model, atemporal.
That is why [VTPF](cite:cites vtpf) was introduced, a TPF feature that adds versioning capabilities to the interface.
It enables low-cost publication of versioned datasets, in contrast to endpoints using [temporal SPARQL extensions](cite:cites tsparql,sparqlst).
Furthermore, [datetime content-negotation support was added to TPF](cite:cites mementoldf) using [Memento](cite:cites memento),
which is an HTTP framework that enables time-based access to HTTP resources.
It does this by providing datetime content-negotiation for HTTP resources.
With this, users can access past versions of resources, or in this case, datasets through TPF interfaces.

As such, there is a need for an efficient RDF archive storage solution that can be used in the backend of such an interface.
Since TPF enables paged triple pattern query results, such a store solution must enable offsettable and limited triple pattern queries,
as is already possible using some atemporal triple stores such as [HDT](cite:cites hdt).
An appropriate RDF archive storage solution should therefore also enable versioned triple pattern queries to be offsettable and limited.
In this work, we introduce a storage technique that conforms to these requirements.
Our contributions are:

1. a scalable RDF archive storage model with compression;
2. efficient indexing methods and querying algorithms that allow triple pattern queries *at*, *between* and *for* different versions to be evaluated efficiently;
3. queries return results streams that can be offsetted and limited;
4. OSTRICH, an open-source implementation of this approach; and
5. an extensive evaluation of our technique compared to other approaches using an existing RDF archiving benchmark.

These versioned querying possibilities correspond to the capabilities of the VTPF interface,
which makes it possible to use implementations of this approach as the back-end for RDF archives that are published and queryable at a low cost.

This article is structured as follows.
In the next section, we start by introducing the related work in [](#related-work) and our problem statement in [](#problem-statement).
Next, in [](#fundamentals), we introduce the basic concepts of our approach,
followed by our storage approach in [](#storage) and the accompanied querying algorithms in [](#querying).
After that, we present and discuss the evaluation of our implementation in [](#evaluation).
Finally, we present our conclusions in [](#conclusions).
