## Introduction
{:#introduction}

In the area of data analysis,
there is an ongoing need for maintaining the history of datasets.
This can be used for looking up data at certain points in time,
requesting evolving changes,
or querying for the temporal validity of these data [](cite:cites archiving).
With the continuously increasing number of [Linked Open Datasets](cite:cites linkeddata),
this is an apparent issue for [RDF](cite:cites spec:rdf) data as well.
While the RDF data model is atemporal, Linked Datasets typically [change over time](cite:cites datasetdynamics) on
[dataset, schema and/or instance level](cite:cites diachronql). These refer to additions,
changes or deletions of respectively complete datasets, ontologies and separate facts.
While some evolving datasets, such as [DBpedia](dbpedia),
are published as separate dumps per version,
efficient access to prior versions is often limited.

A [2015 survey on archiving Linked Open Data](cite:cites archiving) illustrated the need for improved versioning capabilities,
as current RDF archiving approaches have scalability issues at Web-scale.
They either perform well for versioned query evaluation at the cost of large storage space requirements,
or they require less storage space at the cost of slower query evaluation.
Furthermore, no existing solution performs well for all versioned query types, i.e., querying *at*, *between*, and *for* different versions.
<span class="comment" data-author="RV">Perhaps useful to explain each of the query types here. I understood, but takes some thinking work.</span>
An efficient RDF archive solution should have a scalable *storage model*,
efficient *compression* and *indexing methods* that should enable expressive versioned querying [](cite:cites archiving).
The performance of existing solutions in each of these areas is limited and should be improved.

The [SPARQL query language](cite:cites spec:sparqllang) is the standard for querying RDF data.
The basis for most SPARQL query engines is the ability to query triples using triple patterns.
As such, triple stores should allow triple pattern access for efficient lookups.
This means that RDF archives should at least offer the same capabilities,
possibly enhanced with additional version-related capabilities.

SPARQL query engines can optimize query resolution when triple stores have more advanced capabilities.
When query results are large for example, stream-based results can allow for more memory-efficient processing.
Furthermore, if only a subset of such a large stream is needed,
the capabilities of offsetting and limitting this stream for a certain number of triples reduces processing time.
Not only can this be used behind a SPARQL endpoint, these capabilities also form the basis
of the Web-friendly [Triple Pattern Fragments](cite:cites ldf) (TPF) interface,
which provides access to RDF datasets using triple pattern queries where results are paged collections.
The TPF interface also offers optional versioning capabilities using [VTPF](cite:cites vtpf),
and [datetime content-negotation](cite:cites mementoldf) using [Memento](cite:cites memento).

As such, there is a need for an efficient RDF archive storage solution that allows versioned triple pattern queries
with result streams that have offset and limit capabilities.
In this work, we introduce a storage technique that conforms to these requirements.
Our contributions are:

1. a scalable RDF archive storage model with compression;
2. efficient indexing methods and querying algorithms that allow triple pattern queries *at*, *between*, and *for* different versions to be evaluated efficiently;
3. queries return result streams that can be offsetted and limited;
4. OSTRICH, an open-source implementation of this approach; and
5. an extensive evaluation of OSTRICH compared to other approaches using an existing RDF archiving benchmark.

This article is structured as follows.
In the next section, we start by introducing the related work in [](#related-work) and our problem statement in [](#problem-statement).
Next, in [](#fundamentals), we introduce the basic concepts of our approach,
followed by our storage approach in [](#storage) and the accompanied querying algorithms in [](#querying).
After that, we present and discuss the evaluation of our implementation in [](#evaluation).
Finally, we present our conclusions in [](#conclusions).
