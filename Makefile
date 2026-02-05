# Makefile for gem5 Docker setup
# Cross-platform compatible

.PHONY: help build build-dev build-prebuilt run run-dev shell test clean push all

# Default target
help:
	@echo "gem5 Docker Setup - Available Commands"
	@echo "========================================"
	@echo ""
	@echo "Build Commands:"
	@echo "  make build          - Build development image for current architecture"
	@echo "  make build-dev      - Build development image (alias)"
	@echo "  make build-prebuilt - Build pre-built image with gem5 binaries"
	@echo "  make build-all      - Build all images"
	@echo ""
	@echo "Run Commands:"
	@echo "  make run            - Run development container"
	@echo "  make run-dev        - Run development container (alias)"
	@echo "  make shell          - Start interactive shell in container"
	@echo ""
	@echo "gem5 Build Commands:"
	@echo "  make gem5-build              - Build gem5 inside container"
	@echo "  make gem5-build ISA=X86      - Build gem5 for X86"
	@echo "  make gem5-build ISA=ARM TYPE=debug"
	@echo "  make gem5-build-all          - Build gem5 for all ISAs"
	@echo ""
	@echo "Test Commands:"
	@echo "  make test           - Run health checks"
	@echo "  make test-build     - Test build script"
	@echo ""
	@echo "Other Commands:"
	@echo "  make clean          - Remove containers and images"
	@echo "  make push           - Push images to registry"
	@echo ""
	@echo "Environment Variables:"
	@echo "  GEM5_VERSION        - gem5 version to use (default: v25.1)"
	@echo "  ISA                 - Target ISA for build (default: ARM)"
	@echo "  TYPE                - Build type: debug, opt, fast (default: opt)"
	@echo "  JOBS                - Parallel jobs (default: auto)"
	@echo ""

# Variables
GEM5_VERSION ?= v25.1
ISA ?= ARM
TYPE ?= opt
JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
IMAGE_NAME ?= gem5
CONTAINER_NAME ?= gem5-dev

# Detect architecture
ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
    PLATFORM := linux/amd64
    DEFAULT_ISA := X86
else ifeq ($(ARCH),arm64)
    PLATFORM := linux/arm64
    DEFAULT_ISA := ARM
else ifeq ($(ARCH),aarch64)
    PLATFORM := linux/arm64
    DEFAULT_ISA := ARM
else
    PLATFORM := linux/amd64
    DEFAULT_ISA := X86
endif

# Build development image
build: build-dev

build-dev:
	@echo "Building gem5 development image for $(PLATFORM)..."
	docker build \
		--platform $(PLATFORM) \
		--build-arg GEM5_VERSION=$(GEM5_VERSION) \
		-t $(IMAGE_NAME):dev \
		-f Dockerfile .

# Build pre-built image
build-prebuilt:
	@echo "Building gem5 pre-built image for $(PLATFORM)..."
	docker build \
		--platform $(PLATFORM) \
		--build-arg GEM5_VERSION=$(GEM5_VERSION) \
		--build-arg BUILD_ISA=$(DEFAULT_ISA) \
		-t $(IMAGE_NAME):prebuilt \
		-f Dockerfile.prebuilt .

# Build all images
build-all: build-dev build-prebuilt

# Run development container
run: run-dev

run-dev:
	@echo "Starting gem5 development container..."
	docker run -d --name $(CONTAINER_NAME) \
		-v $(PWD)/workspace:/workspace \
		$(IMAGE_NAME):dev tail -f /dev/null
	@echo "Container started. Use 'make shell' to access."

# Interactive shell
shell:
	@if docker ps -q -f name=$(CONTAINER_NAME) | grep -q .; then \
		docker exec -it $(CONTAINER_NAME) /bin/bash; \
	else \
		docker run -it --rm \
			--name $(CONTAINER_NAME) \
			-v $(PWD)/workspace:/workspace \
			$(IMAGE_NAME):dev /bin/bash; \
	fi

# Build gem5 inside container
gem5-build:
	@echo "Building gem5 for ISA=$(ISA) TYPE=$(TYPE) JOBS=$(JOBS)..."
	@if docker ps -q -f name=$(CONTAINER_NAME) | grep -q .; then \
		docker exec $(CONTAINER_NAME) /usr/local/bin/build-gem5.sh --isa $(ISA) --type $(TYPE) --jobs $(JOBS); \
	else \
		docker run --rm \
			-v $(PWD)/workspace:/workspace \
			$(IMAGE_NAME):dev /usr/local/bin/build-gem5.sh --isa $(ISA) --type $(TYPE) --jobs $(JOBS); \
	fi

gem5-build-all:
	@echo "Building gem5 for all ISAs with TYPE=$(TYPE)..."
	@if docker ps -q -f name=$(CONTAINER_NAME) | grep -q .; then \
		docker exec $(CONTAINER_NAME) /usr/local/bin/build-gem5.sh --all --type $(TYPE) --jobs $(JOBS); \
	else \
		docker run --rm \
			-v $(PWD)/workspace:/workspace \
			$(IMAGE_NAME):dev /usr/local/bin/build-gem5.sh --all --type $(TYPE) --jobs $(JOBS); \
	fi

# Run tests
test:
	@echo "Running health checks..."
	@docker run --rm $(IMAGE_NAME):dev /usr/local/bin/healthcheck.sh

test-build:
	@echo "Testing build script..."
	@docker run --rm $(IMAGE_NAME):dev bash -c "bash -n /usr/local/bin/build-gem5.sh && echo 'Build script syntax OK'"
	@docker run --rm $(IMAGE_NAME):dev /usr/local/bin/build-gem5.sh --help

# Clean up
clean:
	@echo "Stopping and removing containers..."
	-docker stop $(CONTAINER_NAME) 2>/dev/null
	-docker rm -f $(CONTAINER_NAME) 2>/dev/null
	@echo "Removing images..."
	-docker rmi $(IMAGE_NAME):dev $(IMAGE_NAME):prebuilt 2>/dev/null
	@echo "Cleanup complete."

# Push to registry
push:
	@echo "Pushing images to registry..."
	docker push $(IMAGE_NAME):dev
	docker push $(IMAGE_NAME):prebuilt
