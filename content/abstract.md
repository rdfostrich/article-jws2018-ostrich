## Abstract
<!-- Context      -->
Linked Open Datasets on the Web can change over time for a number of reasons,
such as the addition or removal of facts,
changes in the used ontologies,
or mistakes that are resolved.
While in many cases most attention is given to the latest version of a dataset,
a lot of useful information can still be found in or over the previous versions.
<!-- Need         -->
In order to exploit this historical dataset information in dataset analysis,
such as concept drift analysis,
there is an emerging need to maintain the history of these datasets as RDF archives.
<!-- Task         -->
This requires RDF archives containing multiple versions to be stored efficiently,
while at the same time enabling efficient querying.
<!-- Object       -->
In this article, we introduce a storage technique that is able to store RDF archives
with a low storage overhead by compressing consecutive versions.
Furthermore, we introduce algorithms based on this technique for efficiently evaluating
queries *at* a certain version, *between* two versions and *for* version.
Finally, we evaluate OSTRICH, an implementation of this storage technique and its accompanied querying algorithms,
using an RDF archiving benchmark.
<!-- Findings     -->
Results show that ...

{:.todo}
fill in

<!-- Conclusion   -->
Our storage technique enables efficient RDF archive querying
while at the same time storing the archive with a low overhead.
This allows data owners to store and query multiple versions of their dataset efficiently,
which lowers the barrier towards historical dataset analysis.
<!-- Perspectives -->

