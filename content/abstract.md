## Abstract
<!-- Context      -->
The latest version of Linked Open Datasets typically receive most of the attention for publishing on the Web.
Nevertheless, a lot of useful information can still be found in or over the previous versions.
<!-- Need         -->
In order to exploit this historical dataset information in dataset analysis,
such as concept drift analysis,
there is an emerging need to maintain the history of these datasets as RDF archives.
Existing approaches either require a lot of storage space for maintaining these archives,
or their interface is not expressive or efficient enough with respect to the querying demand for versioned datasets.
<!-- Task         -->
Therefore, RDF archives containing multiple versions must be stored efficiently,
while at the same time enabling efficient querying.
<!-- Object       -->
In this article, we introduce a technique that is able to store RDF archives
with a low storage overhead by compressing consecutive versions and adding metadata for reducing lookup times.
Furthermore, we introduce algorithms based on this technique for efficiently evaluating
queries *at* a certain version, *between* two versions and *for* versions.
Finally, we evaluate OSTRICH, an implementation of this technique using an RDF archiving benchmark.
<!-- Findings     -->
Results show that our approach introduces a new trade-off regarding storage space, ingestion time and querying efficiency.
By storing and processing more during ingestion time,
we can significantly lower the average lookup time for versioning queries when compared to other approaches.
For many smaller dataset versions, our approach performs relatively better than for few large dataset versions compared to other approaches.
Furthermore, our approach enables efficient offsets in versioned query result streams,
which is useful for random access in results
but not explicitly supported in other existing approaches.
<!-- Conclusion   -->
Our storage technique reduces query evaluation time for versioning queries by moving part of it
to a preprocessing step during ingestion time, which only in some cases increases storage space when compared to other appraches.
This allows data owners to store and query multiple versions of their dataset efficiently,
<!-- Perspectives -->
which lowers the barrier towards historical dataset publication and analysis at a low cost.

<span id="keywords"><span class="title">Keywords:</span> Linked Data, RDF archiving, Semantic Data Versioning, storage, querying</span>
