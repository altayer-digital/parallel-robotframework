#!/usr/bin/env bash

docker run --rm  -d \
           -e USERNAME="Hammad Ahmed" \
           --net=host \
           -e ROBOT_TESTS=./suite   \
           -e ROBOT_LOGS=/parallel_results/test-$2   \
           -e ROBOT_TEST=$1 \
           -e ROBOT_CTAG=$7  \
           -e REMOTE_URL=   \
           -e ROBOT_RUN=$6   \
           -e WEBSITE=$3   \
           -e LANGUAGE=$4   \
           -e REMOTE_DESIRED=$5   \
           -e PABOT_PROC=1      \
           -e TIMEOUT=$8     \
           -v "$PWD/execution/scripts":/execution/scripts/ \
           -v "$PWD/execution/parallel_wrapper/":/execution/parallel_wrapper/ \
           -v "$PWD/parallel_results/test-$2":/parallel_results/test-$2 \
           -v "$PWD/":/suite/ \
           --security-opt seccomp:unconfined \
           --shm-size "1G" \
           --name $3_$1 \
           $9