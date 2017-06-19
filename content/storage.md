## Storage
{:#storage}

In this section, we introduce a storage approach for storing multiple versions of an RDF dataset.
We focus on the part of answering our research question on how to efficiently store and query RDF archives, as introduced in [](#introduction).

In order to handle VM, DM and VQ queries efficiently, our storage solution is a hybrid IC/CB/TB solution.
In summary, our approach consists of an initial dataset snapshot followed by a delta chain ([TailR](cite:cites tailr)),
where this chain is compressed in a B+Tree for TB-storage ([Dydra](cite:cites dydra)).
Furthermore, we store additional metadata for convenience and improving lookup times ([HDT](cite:cites hdt)).
Triple components are encoded in a dictionary for improved compression ([HDT](cite:cites hdt))
and we provide multiple indexes for different triple component orders ([RDF-3X](cite:cites rdf3x), [Hexastore](cite:cites hexastore)).
