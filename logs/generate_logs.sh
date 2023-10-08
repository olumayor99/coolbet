#!/usr/bin/env bash

limit=30

echo "0" > abc.log

for (( i = 10; i <= limit; ++i )); do
    echo "$i" > abc.log.$i
done