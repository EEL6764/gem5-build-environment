#!/bin/bash
set -e


if [ ! -d "${GEM5_HOME:-/opt/gem5}" ]; then
    echo "FAIL: gem5 directory not found"
    exit 1
fi

if ! command -v scons &> /dev/null; then
    echo "FAIL: scons not found"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "FAIL: python3 not found"
    exit 1
fi

if ! command -v gcc &> /dev/null; then
    echo "FAIL: gcc not found"
    exit 1
fi

if ! command -v g++ &> /dev/null; then
    echo "FAIL: g++ not found"
    exit 1
fi

GEM5_BINARIES=$(find "${GEM5_HOME:-/opt/gem5}/build" -name "gem5.*" -executable -type f 2>/dev/null || true)

if [ -n "$GEM5_BINARIES" ]; then
    echo "OK: gem5 binaries found"
    echo "$GEM5_BINARIES"
else
    echo "OK: gem5 development environment ready (no pre-built binaries)"
fi

REQUIRED_LIBS=("libz.so" "libprotobuf.so" "libboost_filesystem.so")
MISSING_LIBS=()

for lib in "${REQUIRED_LIBS[@]}"; do
    if ! ldconfig -p | grep -q "$lib"; then
        MISSING_LIBS+=("$lib")
    fi
done

if [ ${#MISSING_LIBS[@]} -gt 0 ]; then
    echo "WARNING: Some libraries may be missing: ${MISSING_LIBS[*]}"
fi

echo "OK: Health check passed"
exit 0
