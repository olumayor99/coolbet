#!/usr/bin/env bash

int=0

for old_name in `ls | grep abc.log`; do
    rm $old_name
    int=$(($int+1))
done

for old_name in `ls rotated_logs | grep abc.log`; do
    rm rotated_logs/$old_name
    int=$(($int+1))
done