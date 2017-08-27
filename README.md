```
abstract
introduction
    motivation (mention tpf in here)
preliminaries
    (on rdf archiving)
    Querying
    Storage policies
problem statement
    (provide groundwork for evaluation structure)
    research questions
related work
    archiving solutions
        hdt
    archiving benchmarks
OSTRICH
storage (data structure)
ingestion algo
querying (algos for VM, DM and VQ + corresponding counts)
VTPF (interface)
evaluation
    experimental setup
        implementation (cpp+node)
    ingestion
    querying
    discussion
conclusion
```

## Build
```
bundle install
bundle exec nanoc compile
```

## Development mode
```
bundle install
bundle exec guard
```

## Live version
TODO

## License
This article is written by [Ruben Taelman](http://rubensworks.net/) and colleagues.

This article is copyrighted by [Ghent University – imec](http://idlab.ugent.be/)
and released under the [MIT license](http://opensource.org/licenses/MIT).
