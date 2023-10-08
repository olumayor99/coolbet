#!/usr/bin/env bash

int=1

for old_name in `ls | grep abc.log | sort -n -t . -k 3`; do
    new_name=abc.log.$int
    mv $old_name $new_name
    echo "$old_name -> $new_name"
    int=$(($int+1))
done