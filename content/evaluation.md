## Evaluation
{:#evaluation}

In this section, we evaluate our proposed storage technique and querying algorithms.
We start by introducing OSTRICH, an implementation of our proposed solution.
After that, we describe the setup of our experiments, followed by presenting our results.
Finally, we discuss these results.

### Implementation

In this section, we describe OSTRICH, a software implementation of the storage and querying techniques that are described in this article.
OSTRICH stands for _Offset-enabled STore for TRIple CHangesets_.
It is implemented in C/C++ and is available on [GitHub](https://github.com/rdfostrich/ostrich) under an open license.
In the scope of this work, OSTRICH currently supports a single snapshot and delta chain.
OSTRICH uses [HDT](cite:cites hdt) as snapshot technology as it conforms to all the [requirements](#snapshot-storage) for our approach.
Furthermore, for our indexes we use [Kyoto Cabinet](http://fallabs.com/kyotocabinet/),
which provides a highly efficient memory-mapped B+Tree implementation with compression support.
Memory-mapping is required so that not all data must be loaded in-memory when queries are evaluated,
which is not always possible for large datasets.
For our delta dictionary, we reuse HDT's dictionary implementation with adjustments to make it work with unsorted triple components.
We compress this delta dictionary using [GZIP](http://www.gzip.org/).
Finally, for storing our addition counts, we use the Hash Database of Kyoto Cabinet, which is also memory-mapped.

We provide a developer-friendly C/C++ API for ingesting and querying data based on an OSTRICH store.
Additionally, we provide command-line tools for ingesting data into an OSTRICH store,
or evaluating VM, DM or VQ triple pattern queries for any given limit and offset against a store.
Furthermore, we implemented [Node JavaScript bindings](https://github.com/rdfostrich/ostrich-node) that
exposes the OSTRICH API for ingesting and querying to JavaScript applications.
We used these bindings to [expose an OSTRICH store](http://versioned.linkeddatafragments.org/bear)
containing a dataset with 30M triples in 10 versions using [TPF](cite:cites ldf), with the [VTPF feature](cite:cites vtpf).

In order to ensure correctness, we implemented more than 500 passing unit tests in in the C/C++ and JavaScript implementations
to check the essential ingestion and lookup functionality and edge cases.
The C/C++ implementation consists of more than 6000 lines of code and the corresponding Node bindings contains 1000 lines of code.

### Experimental Setup

As mentioned before in [](#related-work-benchmarks), we evaluate our approach using the BEAR benchmark.
To test the scalability of our approach for datasets with few and large versions, we use the BEAR-A benchmark.
We use the ten first versions of the BEAR-A dataset, which contains an average of 17M triples per version.
This dataset was compiled from the [Dynamic Linked Data Observatory](http://swse.deri.org/dyldo/).
For testing for datasets with many smaller versions, we use BEAR-B with the daily and hourly granularities.
The daily dataset contains 89 versions and the hourly dataset contains 1299 version,
both of them have around 48K triples per version.

For BEAR-A, we use all 7 of the provided querysets, each containing at most 50 triple pattern queries,
once with a high result cardinality and once with a low result cardinality.
These querysets correspond to all possible triple pattern materializations, except for triple patterns where each component is blank.
For BEAR-B, only two querysets are provided, those that correspond to `?P?` and `?PO` queries.
The number of BEAR-B queries is more limited, but they are derived from real-world DBpedia queries,
which makes them useful for testing real-world applicability.
All of these queries can be evaluated as VM queries on all versions,
as DM between the first version and all other versions,
and as VQ.

For a complete comparison with other approaches, we re-evaluated BEAR's Jena and HDT-based RDF archive implementations.
More specifically, we ran all BEAR-A queries against Jena with the IC, CB, TB and hybrid CB/TB implementation,
and HDT with the IC and CB implementations
using the BEAR-A dataset for ten versions.
We did the same for BEAR-B with the daily and hourly dataset.
Finally, we evaluated OSTRICH for the same queries and datasets.

Our experiments were executed on a 64-bit
Ubuntu 14.04 machine with 128 GB of memory and a
24-core 2.40 GHz cpu.

{:.todo}
offset queries
triple patterns - card:
?s ?p ?o - 43907
http://dbpedia.org/ontology/wikiPageRevisionLink - 7854
http://dbpedia.org/ontology/wikiPageExtracted - 7825
http://dbpedia.org/ontology/wikiPageRevisionID - 7844
http://dbpedia.org/ontology/wikiPageLength - 6709
http://dbpedia.org/ontology/wikiPageModified - 7854

### Results

In this section, we present the results of our evaluation.
We report the ingestion results, storage sizes and query evaluation times for all cases.

{:.todo}
Write

<figure id="results-ingestion-bear-a" class="table" markdown="1">

| Approach        | Ingestion Time (min) | Size (GB) |
| --------------- |:---------------------|:----------|
| Raw (N-Triples) | /                    | 45        |
| Raw (gzip)      | /                    |  3        |
| OSTRICH         | 2463                 |  5,86     |
| Jena IC         |  443                 | 32,04     |
| Jena CB         |  226                 | 17,79     |
| Jena TB         | 1746                 | 80,35     |
| Jena CB/TB      |  679                 | 30,43     |
| HDT IC          |   33,85              |  5,21     |
| HDT CB          |   17,56              |  2,62     |

<figcaption markdown="block">
Ingestion times and storage sizes for each of the RDF archive approaches for the first ten versions of BEAR-A.
</figcaption>
</figure>

<figure id="results-ingestion-bear-b-daily" class="table" markdown="1">

| Approach        | Ingestion Time (min) | Size (MB) |
| --------------- |:---------------------|:----------|
| Raw (N-Triples) | /                    | 583       |
| Raw (gzip)      | /                    | 32        |
| OSTRICH         | TODO                 | 23,6      |
| Jena IC         | TODO                 | TODO      |
| Jena CB         | TODO                 | TODO      |
| Jena TB         | TODO                 | TODO      |
| Jena CB/TB      | TODO                 | TODO      |
| HDT IC          | TODO                 | TODO      |
| HDT CB          | TODO                 | TODO      |

<figcaption markdown="block">
Ingestion times and storage sizes for each of the RDF archive approaches for BEAR-B daily.
</figcaption>
</figure>

<figure id="results-ingestion-bear-b-hourly" class="table" markdown="1">

| Approach        | Ingestion Time (min) | Size (MB) |
| --------------- |:---------------------|:----------|
| Raw (N-Triples) | /                    | 8929      |
| Raw (gzip)      | /                    |  467      |
| OSTRICH         | 5680,09              |  710,41   |
| Jena IC         |  142,26              | 6233,92   |
| Jena CB         |  173,48              |  473,41   |
| Jena TB         |   70,56              | 3678,89   |
| Jena CB/TB      |    0,65              |   53,84   |
| HDT IC          |    5,89              | 2127,57   |
| HDT CB          |    0,07              |   24,39   |

<figcaption markdown="block">
Ingestion times and storage sizes for each of the RDF archive approaches for BEAR-B hourly.
</figcaption>
</figure>

<figure id="results-ostrich-ingestion-rate-beara">
<img src="img/results-ostrich-ingestion-rate-beara.svg" alt="[BEAR-A OSTRICH ingestion rate]" height="150em">
<figcaption markdown="block">
OSTRICH ingestion durations for each consecutive BEAR-A version in minutes for an increasing number of versions,
showing a lineair growth.
</figcaption>
</figure>

<figure id="results-ostrich-ingestion-size-beara">
<img src="img/results-ostrich-ingestion-size-beara.svg" alt="[BEAR-A OSTRICH ingestion sizes]" height="150em">
<figcaption markdown="block">
Cumulative OSTRICH store sizes for each consecutive BEAR-A version in GB for an increasing number of versions,
showing a lineair growth.
</figcaption>
</figure>

<figure id="results-ostrich-ingestion-rate-bearb-hourly">
<img src="img/results-ostrich-ingestion-rate-bearb-hourly.svg" alt="[BEAR-B-hourly OSTRICH ingestion rate]" height="150em">
<figcaption markdown="block">
OSTRICH ingestion durations for each consecutive BEAR-B-hourly version in minutes for an increasing number of versions,
showing a lineair growth.
</figcaption>
</figure>

{:.todo}
possible cause for weird behaviour around V 1200: large KC tree leaves causing a lot of reorganizations, which take a long time.

<figure id="results-ostrich-ingestion-size-bearb-hourly">
<img src="img/results-ostrich-ingestion-size-bearb-hourly.svg" alt="[BEAR-B-hourly OSTRICH ingestion sizes]" height="150em">
<figcaption markdown="block">
Cumulative OSTRICH store sizes for each consecutive BEAR-B-hourly version in GB for an increasing number of versions,
showing a lineair growth.
</figcaption>
</figure>

<figure id="results-beara-vm-sumary">
<img src="img/query/results_beara-vm-summary.svg" alt="[BEAR-A VM]" height="200em">
<figcaption markdown="block">
Median BEAR-A VM query results for all triple patterns for all versions.
</figcaption>
</figure>

<figure id="results-beara-dm-summary">
<img src="img/query/results_beara-dm-summary.svg" alt="[BEAR-A DM]" height="200em">
<figcaption markdown="block">
Median BEAR-A DM query results for all triple patterns from version 0 to all other versions.
</figcaption>
</figure>

<figure id="results-beara-summary">
<img src="img/query/results_beara-vq-summary.svg" alt="[BEAR-A VQ]" height="200em">
<figcaption markdown="block">
Median BEAR-A VQ query results for all triple patterns.
</figcaption>
</figure>

<figure id="results-bearb-hourly-vm-sumary">
<img src="img/query/results_bearb-hourly-vm-summary.svg" alt="[BEAR-B-hourly VM]" height="200em">
<figcaption markdown="block">
Median BEAR-B-hourly VM query results for all triple patterns for all versions.
</figcaption>
</figure>

<figure id="results-bearb-hourly-dm-summary">
<img src="img/query/results_bearb-hourly-dm-summary.svg" alt="[BEAR-B-hourly DM]" height="200em">
<figcaption markdown="block">
Median BEAR-B-hourly DM query results for all triple patterns from version 0 to all other versions.
</figcaption>
</figure>

<figure id="results-bearb-hourly-summary">
<img src="img/query/results_bearb-hourly-vq-summary.svg" alt="[BEAR-B-hourly VQ]" height="200em">
<figcaption markdown="block">
Median BEAR-B-hourly VQ query results for all triple patterns.
</figcaption>
</figure>

<figure id="results-offset-vm">
<img src="img/query/results_offsets-vm.svg" alt="[Offsets VM]" height="200em">
<figcaption markdown="block">
Median VM query results for different offsets over all versions in the BEAR-A dataset.
</figcaption>
</figure>

<figure id="results-offset-dm">
<img src="img/query/results_offsets-dm.svg" alt="[Offsets DM]" height="200em">
<figcaption markdown="block">
Median DM query results for different offsets between version 0 and all other versions in the BEAR-A dataset.
</figcaption>
</figure>

<figure id="results-offset-vq">
<img src="img/query/results_offsets-vq.svg" alt="[Offsets VQ]" height="200em">
<figcaption markdown="block">
Median VQ query results for different offsets in the BEAR-A dataset.
</figcaption>
</figure>

{:.todo}
Summary plots, all other detailed plots in appendix
OSTRICH increasing offset: once low card and once high card, for S?? limit inf, ?P? limit inf, ??O limit inf
    for VM, DM and VQ

{:.todo}
appendix: (each plot contains results for 7 storage approaches, one plot for low and one for high cardinality)
    BEAR-A:
        VM: (10 versions)
            S??, ?P?, ??O, SP?, ?PO, S?O, SPO
        DM: (0 to 9 versions)
            S??, ?P?, ??O, SP?, ?PO, S?O, SPO
        VQ: (single)
            S??, ?P?, ??O, SP?, ?PO, S?O, SPO
    BEAR-B daily:
        VM: (all versions)
            ?P?, ?PO
        DM: (0 to all other versions)
            ?P?, ?PO
        VQ: (single)
            ?P?, ?PO
    BEAR-B hourly:
        VM: (all versions)
            ?P?, ?PO
        DM: (0 to all other versions)
            ?P?, ?PO
        VQ: (single)
            ?P?, ?PO

### Discussion

{:.todo}
Write