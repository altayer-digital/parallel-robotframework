#!/usr/bin/env bash

python ./execution/parallel_wrapper/executor.py  \
    --include search \
    --exclude empty \
    --test empty \
    --suite empty \
    . \
    ./parallel_results/search.html \
    google   \
    US   \
    True   \
    0  \
    -search \
    single \
    5 \
    web-automation-docker