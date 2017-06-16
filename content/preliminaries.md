## Preliminaries
{:#preliminaries}

Several approaches exist for archiving Linked Data, which will be further discussed in [](#related-work-archiving).
A survey about archiving [Linked Open Data](cite:cites archiving) categorizes these approaches
into three non-orthogonal storage strategies.
<ol>
    <li>The <em>Independent copies (IC)</em> approach creates separate instantiations of datasets for
each change or set of changes.</li>
    <li>The <em>Change-based (CB)</em> approach instead only stores changes between versions.</li>
    <li>The <em>Timestamp-based (TB)</em> approach stores the temporal validity of facts.</li>
</ol>

The storage of RDF archives typically goes hand-in-hand with querying.
[Five foundational query atoms were introduced](cite:cites bear) that cover the retrieval demands in RDF archiving.
<ol>
    <li><em>Version materialization (VM)</em> retrieves data using queries targeted at a single version.</li>
    <li><em>Delta materialization (DM)</em> retrieves query result differences between two versions.</li>
    <li><em>Version query (VQ)</em> annotates query results with the versions in which they are valid.</li>
    <li><em>Cross-version join (CV)</em> joins the results of two queries between versions.</li>
    <li><em>Change materialization (CM)</em> returns a list of versions in which a given query produces
consecutively different results.</li>
</ol>
As discussed in [previous work](cite:cites tpfarchives), CV and CM queries can be simulated in terms of the other ones.
That is why for the remainder of this article, we will focus on VM, DM and VQ queries.
