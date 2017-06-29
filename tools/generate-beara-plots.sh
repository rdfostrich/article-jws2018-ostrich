#!/bin/bash
storages="vm dm vq"
queries="o-high o-low p-high p-low po-high po-low s-high s-low so-low sp-high sp-low spo"
for storage in ${storages[@]}; do
    for query in ${queries[@]}; do
        tmp="content/img/query/result_beara-$storage-$query.tex"
        cp content/img/query/results_beara-template-$storage.tex $tmp
        gsed -i "s/QUERY/$query/" $tmp
        tools/tikz2svg.sh $tmp
        rm $tmp
    done
done

