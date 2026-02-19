.DEFAULT_GOAL := all

export DOCKER_DEFAULT_PLATFORM=linux/amd64
PROJECT_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

CONFIG_FILE ?= $(realpath ./.config)

OUTPUT_FOLDER ?= $(PROJECT_DIR)/build

LATEX_PROGRAM ?= latexmk
LATEX_ARGS ?= -pdf

ifeq ($(CONFIG_FILE),)
$(error .config file must be in this folder on parent folder)
endif

include $(CONFIG_FILE)

OUTPUT_FOLDER := $(abspath $(OUTPUT_FOLDER))

export OUTPUT_FOLDER
export CONFIG_FILE
export LATEX_PROGRAM
export LATEX_ARGS

# Docker configuration
DOCKER_IMAGE_NAME := cv-generator
DOCKER_CONTAINER_NAME := cv-generator
DOCKERFILE_PATH := $(PROJECT_DIR)/containers/Dockerfile

# Determine data source (URL or FILE)
ifdef DATA_URL
    ifdef DATA_FILE
        $(error Both DATA_URL and DATA_FILE are defined in $(CONFIG_FILE). Please use only one.)
    endif
    DATA_SOURCE := $(DATA_URL)
    DATA_SOURCE_TYPE := url
else ifdef DATA_FILE
    DATA_SOURCE := $(abspath $(PROJECT_DIR)/$(DATA_FILE))
    DATA_SOURCE_TYPE := file
else
    $(error Either DATA_URL or DATA_FILE must be defined in $(CONFIG_FILE))
endif


all: build

full: build_container build

build:
	@docker rm -f $(DOCKER_CONTAINER_NAME) 2>/dev/null || true
ifeq ($(DATA_SOURCE_TYPE),url)
	docker run --rm \
		--name $(DOCKER_CONTAINER_NAME) \
		-v "$(OUTPUT_FOLDER):/output" \
		$(DOCKER_IMAGE_NAME) \
		--url "$(DATA_SOURCE)"
else
	docker run --rm \
		--name $(DOCKER_CONTAINER_NAME) \
		-v "$(OUTPUT_FOLDER):/output" \
		-v "$(DATA_SOURCE):/input/data.json:ro" \
		$(DOCKER_IMAGE_NAME) \
		--file /input/data.json
endif

shell:
	@docker rm -f $(DOCKER_CONTAINER_NAME)-shell 2>/dev/null || true
ifeq ($(DATA_SOURCE_TYPE),url)
	docker run --rm -it \
		--name $(DOCKER_CONTAINER_NAME)-shell \
		-v "$(OUTPUT_FOLDER):/output" \
		--entrypoint /bin/bash \
		$(DOCKER_IMAGE_NAME)
else
	docker run --rm -it \
		--name $(DOCKER_CONTAINER_NAME)-shell \
		-v "$(OUTPUT_FOLDER):/output" \
		-v "$(DATA_SOURCE):/input/data.json:ro" \
		--entrypoint /bin/bash \
		$(DOCKER_IMAGE_NAME)
endif

build_container:
	docker build \
		-t $(DOCKER_IMAGE_NAME) \
		-f $(DOCKERFILE_PATH) \
		$(PROJECT_DIR)

stop:
	@docker stop $(DOCKER_CONTAINER_NAME) 2>/dev/null || true
	@docker stop $(DOCKER_CONTAINER_NAME)-shell 2>/dev/null || true

clean:
	@docker rm -f $(DOCKER_CONTAINER_NAME) 2>/dev/null || true
	@docker rm -f $(DOCKER_CONTAINER_NAME)-shell 2>/dev/null || true

clean_image:
	docker rmi $(DOCKER_IMAGE_NAME) || true

.PHONY: all full build build_container shell stop clean clean_image
