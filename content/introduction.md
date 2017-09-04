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
we argue that, due to their combined complexity, supporting both RDF archiving and SPARQL at once is difficult to scale.
Instead, we propose an elementary, but efficient versioned _triple pattern_ index---the basic element of SPARQL---that query engines can use.
In addition, we focus on the performance-critical features of supporting  _stream-based results_ and query _offset_.
Stream-based results allow more memory-efficient processing when query results are large.
The capability to offset (and limit) a large stream reduces processing time if only a subset is needed.
This index can be employed by a SPARQL endpoint, but also by the Web-friendly [Triple Pattern Fragments](cite:cites ldf) (TPF) interface:
a Web API that provides access to RDF datasets by triple pattern and partitions the results in pages.
Optional versioning capabilities are possible using [VTPF](cite:cites vtpf),
or [datetime content-negotiation](cite:cites mementoldf) using [Memento](cite:cites memento).
Concretely,
this work introduces a storage technique with the following contributions:

- a scalable versioned compressed RDF index with offset support and result streaming;
- efficient query algorithms to evaluate triple pattern queries *at*, *between*, and *for* different versions;
- an open-source implementation of this approach called OSTRICH;
- an extensive evaluation of OSTRICH compared to other approaches using an existing RDF archiving benchmark.

This article is structured as follows.
In the next section, we start by introducing the related work in [](#related-work) and our problem statement in [](#problem-statement).
Next, in [](#fundamentals), we introduce the basic concepts of our approach,
followed by our storage approach in [](#storage), our ingestion algorithms in [](#ingestions),
and the accompanied querying algorithms in [](#querying).
After that, we present and discuss the evaluation of our implementation in [](#evaluation).
Finally, we present our conclusions in [](#conclusions).
