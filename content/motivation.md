## Motivation
{:#motivation}

In this section, we motivate the problem we aim to tackly by
first introducing preliminary concepts about the RDF archiving domain,
followed by our problem statement.

### Preliminaries
{:#preliminaries}

[Fernández et. al. define an _RDF archive_](cite:cites bear) as a set of version-annotated triples,
where a version-annotated triple is an RDF triple that is annotated with a label representing the version in which this triple holds.
A _RDF version_ `i` of an RDF archive is then defined as the set of all triples in the RDF archive that are annotated with the label `i`.

Several approaches exist for archiving Linked Data, which will be further discussed in [](#related-work-archiving).
A survey about archiving [Linked Open Data](cite:cites archiving) categorizes these approaches
into three non-orthogonal storage strategies.
<ol>
    <li>The <em>Independent copies (IC)</em> approach creates separate instantiations of datasets for
each change or set of changes.</li>
    <li>The <em>Change-based (CB)</em> approach instead only stores changes (i.e. changesets) between versions.</li>
    <li>The <em>Timestamp-based (TB)</em> approach stores the temporal validity of facts.</li>
</ol>

The storage of RDF archives typically goes hand-in-hand with querying.
[Five foundational query atoms were introduced](cite:cites bear) that cover the retrieval demands in RDF archiving.
<ol>
    <li><em>Version materialization (VM)</em> retrieves data using queries targeted at a single version.</li>
    <li><em>Delta materialization (DM)</em> retrieves query result differences (i.e. changesets) between two versions.</li>
    <li><em>Version query (VQ)</em> annotates query results with the versions in which they are valid.</li>
    <li><em>Cross-version join (CV)</em> joins the results of two queries between versions.</li>
    <li><em>Change materialization (CM)</em> returns a list of versions in which a given query produces
consecutively different results.</li>
</ol>
As discussed in [previous work](cite:cites tpfarchives), CV and CM queries can be simulated in terms of the other ones.
That is why for the remainder of this article, we will focus on VM, DM and VQ queries.

As [mentioned before](cite:cites tpfarchives), there is a correspondence between the storage strategies and the query atoms.
Namely, VM performs best for storage solutions based on IC, because there is indexing on version.
DM works best for CB solutions, because the deltas are already in the appropriate format for DM query results.
Finally, VQ works best for TB solutions, because the timestamp annotation directly corresponds to VQ's result format.

{:.todo}
explain example use cases and figures for VM, DM and VQ (why and how)?

### Problem Statement
{:#problem-statement}

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

In this work, we focus on the second task, storing and querying VM, DM and VQ.
Additionally, as the TPF interface returns triple pattern query results in pages, query results within our store should also be pageable.
This can be achieved by considering the query results as a pull-based stream that can be started at any given offset,
and limited when sufficient elements have been consumed.
Furthermore, the advantage of pull-based streams is that for large amounts of query results,
not every triple should necessarily be kept in memory,
because each resulting element can be consumed and processed by a consumer on-demand.
This leads us to the following research question:
<q id="research-question">How can we efficiently store RDF archives while enabling VM, DM and VQ triple pattern queries with efficient offsets?</q>
The following parts can be identified in this research question:
<ul>
    <li>An efficient RDF archive storage technique.</li>
    <li>VM, DM and VQ triple pattern querying algorithms on top of this storage technique.</li>
    <li>Efficient offsetting of the VM, DM and VQ query result streams.</li>
</ul>
In this work, we introduce solutions to each of these parts in order to come up with an answer to our research question.

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
