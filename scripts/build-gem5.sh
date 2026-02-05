#!/bin/bash
set -e

ISA="${ISA:-ARM}"
BUILD_TYPE="${BUILD_TYPE:-opt}"
JOBS="${JOBS:-$(nproc)}"
USE_KVM="${USE_KVM:-0}"  # Disabled by default for Docker compatibility

SUPPORTED_ISAS=("X86" "ARM" "RISCV")

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --isa ISA         Target ISA (X86, ARM, RISCV)"
    echo "  -t, --type TYPE       Build type (debug, opt, fast)"
    echo "  -j, --jobs N          Number of parallel jobs (default: $(nproc))"
    echo "  -a, --all             Build all ISAs"
    echo "  -k, --kvm             Enable KVM support (disabled by default)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --isa X86 --type opt"
    echo "  $0 --isa ARM --type opt --kvm"
    echo "  $0 --all --type opt"
    exit 0
}

validate_isa() {
    local isa=$1
    for supported in "${SUPPORTED_ISAS[@]}"; do
        if [ "$isa" = "$supported" ]; then
            return 0
        fi
    done
    echo "Error: Unsupported ISA '$isa'"
    echo "Supported ISAs: ${SUPPORTED_ISAS[*]}"
    exit 1
}

build_gem5() {
    local isa=$1
    local build_type=$2
    local jobs=$3
    local use_kvm=$4
    
    echo "=========================================="
    echo "Building gem5 for ISA: $isa"
    echo "Build type: $build_type"
    echo "Parallel jobs: $jobs"
    echo "KVM support: $use_kvm"
    echo "=========================================="
    
    cd "${GEM5_HOME}"
    
    scons "build/${isa}/gem5.${build_type}" -j"${jobs}" --ignore-style USE_KVM="${use_kvm}"
    
    echo "Build completed: build/${isa}/gem5.${build_type}"
}

BUILD_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--isa)
            ISA="$2"
            shift 2
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -a|--all)
            BUILD_ALL=true
            shift
            ;;
        -k|--kvm)
            USE_KVM=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Execute build
if [ "$BUILD_ALL" = true ]; then
    for isa in "${SUPPORTED_ISAS[@]}"; do
        if [ "$isa" != "NULL" ]; then
            build_gem5 "$isa" "$BUILD_TYPE" "$JOBS" "$USE_KVM" || echo "Warning: Build for $isa failed, continuing..."
        fi
    done
else
    validate_isa "$ISA"
    build_gem5 "$ISA" "$BUILD_TYPE" "$JOBS" "$USE_KVM"
fi

echo ""
echo "=========================================="
echo "Build process completed!"
echo "=========================================="
