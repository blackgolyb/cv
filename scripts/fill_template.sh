#!/bin/bash

URL="https://raw.githubusercontent.com/blackgolyb/about_me/main/main.json"
REPO_DIR=$(git rev-parse --show-toplevel)
PYTHON_ACTIVATE="$REPO_DIR/.venv/bin/activate"

cd $REPO_DIR
python3 -m venv .venv
source $PYTHON_ACTIVATE
pip install -r requirements.txt
python3 $REPO_DIR/scripts/fill_template.py -u $URL
deactivate