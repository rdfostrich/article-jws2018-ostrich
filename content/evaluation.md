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

{:.todo}
Write

### Results

{:.todo}
Write

### Discussion

{:.todo}
Write