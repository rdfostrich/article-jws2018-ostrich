## Introduction
{:#introduction}

In the area of data analysis,
there is an ongoing need for maintaining the history of datasets.
This can be used for looking up data at certain points in time,
requesting evolving changes,
or querying for the temporal validity of these data [](cite:cites archiving).
With the continuously increasing number of [Linked Open Datasets](cite:cites linkeddata),
archiving has become an issue for [RDF](cite:cites spec:rdf) data as well.
While the RDF data model itself is atemporal, Linked Datasets typically [change over time](cite:cites datasetdynamics) on
[dataset, schema, and/or instance level](cite:cites diachronql).
Such changes can include additions,
modifications, or deletions of complete datasets, ontologies, and separate facts.
While some evolving datasets, such as [DBpedia](dbpedia),
are published as separate dumps per version,
more direct and efficient access to prior versions is desired.

Consequently,
RDF archiving systems emerged that, for instance, support query engines that use the standard [SPARQL query language](cite:cites spec:sparqllang).
In 2015, however, [a survey on archiving Linked Open Data](cite:cites archiving) illustrated the need for improved versioning capabilities,
as current approaches have scalability issues at Web-scale.
They either perform well for versioned query evaluation, at the cost of large storage space requirements,
or they require less storage space, at the cost of slower query evaluation.
Furthermore, no existing solution performs well for all versioned query types, namely querying *at*, *between*, and *for* different versions.
An efficient RDF archive solution should have a scalable *storage model*,
efficient *compression*, and *indexing methods* that should enable expressive versioned querying [](cite:cites archiving).
The performance of existing solutions in each of these areas is limited and should be improved.

In this article,
we argue that supporting both RDF archiving and SPARQL at once is difficult to scale due to their combined complexity.
Instead, we propose an elementary, but efficient versioned _triple pattern_ index.
A triple pattern is the basic element of SPARQL and, thus, can be used by query engines.

<div style="color: red">I've rewritten the part below to be more strong. Needs som more finetuning</div>

As such, our solution is applicable as:
(a) an alternative index with efficient triple-pattern-based access for existing engines, in order to improve the efficiency of more expressive SPARQL queries; and
(b) a data source for the Web-friendly [Triple Pattern Fragments](cite:cites ldf) (TPF) interface, i.e.,
a Web API that provides access to RDF datasets by triple pattern and partitions the results in pages.
Hence, we focus on the performance-critical features of _stream-based results_, query _offset_ and _cardinality estimation_.
Stream-based results allow more memory-efficient processing when query results are large.
The capability to offset (and limit) a large stream reduces processing time if only a subset is needed.
Cardinality estimation is essential for efficient [query planning](cite:cites ldf,rdf3x) in certain query engines.
Concretely,
this work introduces a storage technique with the following contributions:

- a scalable versioned and compressed RDF *index* with *offset* support and result *streaming*;
- efficient *query algorithms* to evaluate triple pattern queries and perform cardinality estimation *at*, *between*, and *for* different versions, with optional *offsets*;
- an open-source *implementation* of this approach called OSTRICH;
- an extensive *evaluation* of OSTRICH compared to other approaches using an existing RDF archiving benchmark.

The main novelty of this work is the combination of efficient offset-enabled queries over a new index structure for RDF archives.
Note that we do not aim to compete with existing versioned SPARQL engines---full access to the language should be leveraged by umbrella engines, for instance by using Triple Pattern Fragments.
Optional versioning capabilities are possible for TPF by using [VTPF](cite:cites vtpf),
or [datetime content-negotiation](cite:cites mementoldf) through [Memento](cite:cites memento).

This article is structured as follows.
In the next section, we start by introducing the related work and our problem statement in [](#problem-statement).
Next, in [](#fundamentals), we introduce the basic concepts of our approach,
followed by our storage approach in [](#storage), our ingestion algorithms in [](#ingestions),
and the accompanying querying algorithms in [](#querying).
After that, we present and discuss the evaluation of our implementation in [](#evaluation).
Finally, we present our conclusions in [](#conclusions).
