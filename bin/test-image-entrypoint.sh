#!/usr/bin/env bash
set -euo pipefail

swift --version

cd /tmp/TestTool
swift test

printf "All tests are passed!\n"