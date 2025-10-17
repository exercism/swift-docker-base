#!/usr/bin/env bash

# This is the entrypoint script for testing the docker image.
# It is mounted into the container and executed to run the tests.
# It assumes that the test tool is mounted at /tmp/TestTool.
# This script is not meant to be run directly on the host machine.

set -euo pipefail

swift --version

cd /tmp/TestTool
swift test

printf "All tests are passed!\n"