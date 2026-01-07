export DOCKER_DEFAULT_PLATFORM=linux/amd64
PROJECT_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

CONFIG_FILE ?= $(realpath ./.config)

BUILD_FOLDER ?= $(PROJECT_DIR)/build/build
SRC_FOLDER ?= $(PROJECT_DIR)/build/src
# MAIN_FILE ?= "main.tex"
LATEX_PROGRAM ?= "latexmk"
LATEX_ARGS ?= "-pdf"

ifeq ($(CONFIG_FILE),)
$(error .config file must be in this folder on parent folder)
endif

include $(CONFIG_FILE)

SRC_FOLDER		:= $(abspath $(SRC_FOLDER))
BUILD_FOLDER	:= $(abspath $(BUILD_FOLDER))

export SRC_FOLDER
export BUILD_FOLDER
export CONFIG_FILE
# export MAIN_FILE
export LATEX_PROGRAM
export LATEX_ARGS


all: fill build post_build

pre_fill:
	rm -rf ${BUILD_FOLDER} && mkdir -p ${BUILD_FOLDER}

fill: pre_fill
	BUILD_DIR=${SRC_FOLDER} sh ${PROJECT_DIR}/scripts/fill_template.sh ${FILE}

publish: all
	cp ${BUILD_FOLDER}/${CV_FILE_NAME}.pdf ${PROJECT_DIR}/published/${CV_FILE_NAME}.pdf

post_build:
	mv ${BUILD_FOLDER}/main.pdf ${BUILD_FOLDER}/${CV_FILE_NAME}.pdf

build:
	docker compose -f ${PROJECT_DIR}/containers/docker-compose-build.yml up

compile_container: write_settings
	docker compose -f ${PROJECT_DIR}/containers/docker-compose-build.yml build


.PHONY: all build compile_container write_settings
