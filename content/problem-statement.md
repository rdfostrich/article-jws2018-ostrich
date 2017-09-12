## Problem statement
{:#problem-statement}

As mentioned in [](#introduction), no RDF archiving solutions exist that allow
efficient triple pattern querying _at_, _between_, and _for_ different versions,
in combination with a scalable _storage model_ and efficient _compression_.
In the context of query engines, streams are typically used to return query results,
on which offsets and limits can be applied to reduce processing time if only a subset is needed.
As such, RDF archiving solutions should also allow query results to be returned as offsettable streams.
The ability to achieve such stream subsets is limited in existing solutions.

This leads us to the following research question:
<q id="research-question">How can we store RDF archives to enable efficient VM, DM and VQ triple pattern queries with offsets?</q>

In summary, we aim to lower query evaluation times by processing and storing more metadata during ingestion time.
That is because this processing then happens only once per version, instead of every time during lookup.
This will increase ingestion times, but will improve the efficiency of performance-critical features
within query engines and Linked Data interfaces, such as querying with offsets.
We focus on evaluating version materialization (VM), delta materialization (DM), and version (VQ) queries efficiently,
as CV and CM queries can be expressed in [terms of the other ones](cite:cites tpfarchives).

The following requirements can be identified in our research question:

- an efficient RDF archive storage technique;
- VM, DM and VQ triple pattern querying algorithms on top of this storage technique;
- efficient offsetting of the VM, DM, and VQ query result streams.

In this work, we introduce solutions to each of these parts in order to come up with an answer to our research question.
To this end, we introduce the following hypotheses:

1. {:#hypothesis-qualitative-querying}
The selected versions have no influence on the querying efficiency of VM and DM triple pattern queries in our approach.
2. {:#hypothesis-qualitative-ic}
Our approach requires *less* storage space than IC-based approaches, but querying is *slower* for VM and *equal* or *faster* for DM and VQ.
3. {:#hypothesis-qualitative-cb}
Our approach requires *more* storage space than CB-based approaches, but querying is *equal* or *faster*.
4. {:#hypothesis-qualitative-ingestion}
Average query times are lower than other non-IC approaches, at the cost of increased ingestion time.
