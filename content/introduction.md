## Introduction
{:#introduction}

The number of [Linked Open Datasets](cite:cites linkeddata) using the [RDF](cite:cites spec:rdf) data model is continuously increasing.
RDF allows the formation of directed, labeled graphs, where all elements correspond to resources.
These resources can either be IRIs or literals.
These graphs are represented using _triples_, in which a subject is linked via a predicate to an object.
While the RDF data model is atemporal, Linked Datasets typically [change over time](cite:cites datasetdynamics) on
[dataset, schema and/or instance level](cite:cites diachronql). These refer to additions,
changes or deletions of respectively complete datasets, ontologies and separate facts.
While some evolving datasets, such as [DBpedia](dbpedia),
are published as separate dumps per version, full queryable access over different versions is not always possible.
That is because RDF stores provide no native versioning capabilities for datasets,
instead, they only maintain the latest version of datasets when changes occur.

There is however a need for maintaining the history of datasets in the area of data analysis,
such as looking up data at certain points in time,
requesting changes over time,
or querying for times this data was valid.
Furthermore, this need is illustrated by a [survey on archiving Linked Open Data](cite:cites archiving).
It is pointed out that the current RDF archiving approach have scalability issues when applied at Web-scale.
The authors state that an efficient RDF archive solution should have a scalable *storage model*,
efficient *compression* and *indexing methods* that should enable expressive versioned querying.
Furthermore, RDF archives should be publishable at a low cost, to make them queryable at Web-scale.
For this, a low-cost solution such as the [Triple Pattern Fragments](cite:cites ldf) (TPF) interface
would be ideal. By itself, the TPF interface is, just like the RDF data model, atemporal.
That is why [VTPF](cite:cites vtpf) was introduced, a TPF feature that adds versioning capabilities to the interface.
It enables low-cost publication of versioned datasets, in contrast to endpoints using [temporal SPARQL extensions](cite:cites tsparql,sparqlst).
Furthermore, [datetime content-negotation support was added to TPF](cite:cites mementoldf) using [Memento](cite:cites memento),
which is an HTTP framework that enables time-based access to HTTP resources.
It does this by providing datetime content-negotiation for HTTP resources.
With this, users can access past versions of resources, or in this case, datasets through TPF interfaces.

Versioning also is a popular area in other domains, such as software development.
[Git](cite:cites git) is a distributed version control system, typically used in software development projects,
which enables users to work of text documents independently, and synchronize their versions safely.
Furthermore, it maintains a complete history of the documents by storing the *differences* between each version.
Storing the differences between each version instead of maintaining fully materialized snapshots of each version
can significantly reduce the storage requirements for archives.
Techniques like these are also used in existing RDF archiving solutions.

In this work, we tackle the problem of storing and querying RDF archives efficiently.
We introduce a storage technique for compressing and indexing RDF archives,
together with algorithms for querying these archives *at*, *over* and *for* different versions.
These querying possibilities correspond to the capabilities of the VTPF interface,
which makes it possible to use implementations of this approach as the back-end for RDF archives that are published and queryable at a low cost.
We provide OSTRICH as an open-source implementation of this approach.

This article is structured as follows.
In the next section, we start by introducing some [fundamental concepts](#preliminaries)
required for introducing our problem statement in [](#problem-statement).
After that, we introduce the related work in [](#related-work).
Next, in [](#storage), we introduce our storage approach, followed by the accompanied querying algorithms in [](#querying).
After that, we present and discuss the evaluation of our implementation in [](#evaluation).
Finally, we present our conclusions in [](#conclusions).
