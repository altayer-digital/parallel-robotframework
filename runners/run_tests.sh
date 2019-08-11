#!/usr/bin/env bash

docker run --rm \
           -e USERNAME="Hammad Ahmed" \
           --net=host \
           -e ROBOT_TESTS=./suite   \
           -e ROBOT_LOGS=/results   \
           -e ROBOT_RUN=1   \
           -e WEBSITE=medium   \
           -e ROBOT_RUN=0   \
           -e LANGUAGE=US   \
           -e REMOTE_DESIRED=True   \
           -e TIMEOUT=single     \
           -v "$PWD/runners/":/runners/ \
           -v "$PWD/execution/scripts":/execution/scripts/ \
           -v "$PWD/results/":/results/ \
           -v "$PWD/":/suite/ \
           --security-opt seccomp:unconfined \
           --shm-size "256M" \
           web-automation-docker-2
