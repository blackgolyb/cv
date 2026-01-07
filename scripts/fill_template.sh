#!/bin/bash

REPO_DIR=$(git rev-parse --show-toplevel)

# Load config file as env file
set -o allexport
source $CONFIG_FILE
set +o allexport

URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_DATA}/main/${DATA_FILE}"
PYTHON="$REPO_DIR/.venv/bin/python"

if [ $# -eq 0 ]; then
    $PYTHON $REPO_DIR/scripts/fill_template.py -u $URL
else
    $PYTHON $REPO_DIR/scripts/fill_template.py -f "$1"
fi
