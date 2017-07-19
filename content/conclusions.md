## Conclusions
{:#conclusions}

In this article, we introduced a RDF archive storage method with accompanied algorithms for evaluating VM, DM and VQ queries.
Our storage technique is a hybrid of the IC/CB/TB approaches, because we store sequences of snapshots followed by delta chains.
These delta chains are stored together in a timestamp-based tree.
The evaluation of our OSTRICH implementation shows that this technique offers a new trade-off in terms of ingestion time, storage size and lookup times.
By preprocessing and storing additional data during ingestion, we can reduce lookup times for VM, DM and VQ queries compared to CB and TB approaches.
Furthermore, for datasets with larger amounts of versions, our approach requires less storage space than IC approaches,
at the cost of slightly slower VM queries, but comparable DM queries.
Additionally, VQ queries become increasingly more efficient for datasets with larger amounts of versions compared to IC, CB and TB approaches.

With lookup times of 1ms or less in most cases, OSTRICH is an ideal candidate for Web querying,
as the network latency will typically be higher than that.
At the cost of increased ingestion times, fast lookup times are guaranteed in most cases.
Furthermore, by reusing the highly efficient HDT technique for snapshots,
existing HDT snapshots can be loaded in by OSTRICH directly, and patched with additional versions by OSTRICH afterwards.

OSTRICH fulfills our [requirements](cite:cites tpfarchives) for a back-end RDF archive storage solution
for supporting versioning queries in the TPF framework.
Together with the [VTPF](cite:cites vtpf) interface feature, RDF archives can be queried on the Web at a low cost,
as demonstrated on [a public VTPF entrypoint](http://versioned.linkeddatafragments.org/bear).
TPF only requires triple patterns as foundational query atoms,
which means that TPF clients are able to evaluate full VM SPARQL queries using OSTRICH and VTPF.
In future work, the TPF client will be extended to also support DM and VQ SPARQL queries.

With OSTRICH, we provide a good candidate for publishing and querying RDF archives at Web-scale.
Several opportunities exist for improving this technique in future work,
such as improving the ingestion efficiency, supporting dynamic snapshot creation since we only support a single snapshot and delta chain,
and improving the DM offset efficiency.
Furthermore, branching and merging of different version chains can be investigated.

Our approach succeeds in reducing the cost for publishing RDF archives on the Web.
This lowers the barrier towards intelligent clients in the [Semantic Web](cite:cites semanticweb) that require with *evolving* data,
with the goal of time-sensitive querying over the ever-evolving Web of data.
