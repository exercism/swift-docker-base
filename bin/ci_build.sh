#!/usr/bin/env bash

# This script builds the docker image and runs tests inside a container.
# It requires docker to be installed on the host machine.
# It used to run in CI and can be used locally to verify the image build.

set -euo pipefail

SWIFT_VERSION=6.2
DOCKER_IMAGE_PATH="exercism/swift-docker-base:${SWIFT_VERSION}"
DOCKER_IMAGE_NAME="test-swift-docker-base"
PROJECT_PATH="${PROJECT_PATH:-$PWD}"

printf "Building and testing %s\n" "${DOCKER_IMAGE_PATH}"
docker build -t "${DOCKER_IMAGE_PATH}" .

printf "Creating container from %s\n" "${DOCKER_IMAGE_PATH}"
if docker ps -a --format '{{.Names}}' | grep -q "^${DOCKER_IMAGE_NAME}$"; then
    docker stop "${DOCKER_IMAGE_NAME}" > /dev/null
    docker rm "${DOCKER_IMAGE_NAME}" > /dev/null
fi
docker create \
    --name "${DOCKER_IMAGE_NAME}" \
    --entrypoint /bin/bash \
    -v "${PROJECT_PATH}/bin/test-image-entrypoint.sh:/tmp/test-image-entrypoint.sh:ro" \
    -v "${PROJECT_PATH}/src/TestTool:/tmp/TestTool" \
    "${DOCKER_IMAGE_PATH}" \
    -c "/tmp/test-image-entrypoint.sh" 

printf "Saving docker image.\n"
SIZE_BYTES=$(docker image save "${DOCKER_IMAGE_PATH}" | gzip | wc -c)
SIZE_HR=$(numfmt --to=si <<< "$SIZE_BYTES")
printf "Compressed size (bytes): %s\n" "$SIZE_HR"

printf "Starting container to run tests for %s\n" "${DOCKER_IMAGE_PATH}"
docker start -a "${DOCKER_IMAGE_NAME}"

printf "Removing test container %s\n" "${DOCKER_IMAGE_NAME}"
docker rm "${DOCKER_IMAGE_NAME}"

printf "All done!\n"