## Problem Statement
{:#problem-statement}

{:.todo}
TPF in intro

In [previous work](cite:cites tpfarchives), we discussed the requirements for enabling queries over RDF archives using the TPF framework
for VM, DM and VQ queries.
<ol>
    <li>An extension of the TPF interface for versioning query types.</li>
    <li>A storage solution supporting the query atoms.</li>
    <li>A TPF client that is able to consume the TPF interface extension.</li>
</ol>
The first task was handled through the introducing of [VTPF](cite:cites vtpf),
which is a TPF interface feature for enabling queryable access to RDF archives through VM, DM and VQ triple pattern queries.
The third task is already partially solved by VTPF, as it is designed in such a way that each version of the dataset
is exposed through a separate virtual TPF interface, which allows clients to target each version as a separate datasource.

In this work, we focus on the second task, which leads to the following research question:
<q id="research-question">How can we efficiently store RDF archives while enabling VM, DM and VQ triple pattern queries?</q>
In this work, we will introduce a storage technique that provides a solution to this question.
We introduce the following qualitative hypotheses about our storage technique:
<ol>
    <li id="hypothesis-qualitative-storage">Storage requirements are less than IC-based approaches.</li>
    <li id="hypothesis-qualitative-querying">VM and DM triple pattern query evaluation efficiency is independent of the selected versions.</li>
</ol>
Furthermore, we introduce the following quantitative hypothesis which will be evaluated in this article:
<ol>
    <li id="hypothesis-quantitative-storage">Storing 165M triples across 10 version requires less than 6GB.</li>
    <li id="hypothesis-quantitative-ingestion">Ingestion of 165M triples across 10 version can be done at an average rate of 1 triple per millisecond.</li>
    <li id="hypothesis-quantitative-querying">Evaluation of any VM, DM and VQ triple pattern query can be done in less than 10ms.</li>
</ol>

{:.todo}
Say something about offsets already?