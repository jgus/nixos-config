#!/bin/sh

cd $(dirname $0)

docker build \
    --build-arg uid=$(id -u minecraft) \
    --build-arg gid=$(id -g minecraft) \
    --build-arg java_ver="17" \
    -t minecraft \
    .
