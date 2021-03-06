#!/bin/bash
storages="vm dm vq"
queries="p po"
for storage in ${storages[@]}; do
    tools/tikz2svg.sh content/img/query/results_bearb-hourly-$storage-summary.tex
    for query in ${queries[@]}; do
        tmp="content/img/query/result_bearb-hourly-$storage-$query.tex"
        cp content/img/query/results_bearb-hourly-template-$storage.tex $tmp
        gsed -i "s/QUERY/$query/" $tmp
        tools/tikz2svg.sh $tmp
        rm $tmp
    done
done

