#!/usr/bin/env bash

int=1

mkdir -p rotated_logs

for old_name in `ls | grep abc.log | sort -n -t . -k 3`; do
    new_name=rotated_logs/abc.log.$int
    cp $old_name $new_name
    echo "$old_name -> $new_name"
    int=$(($int+1))
done