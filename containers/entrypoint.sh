#!/bin/bash
set -e

echo "=== CV Generation Process ==="
echo ""

# Default values
DATA_SOURCE=""
BUILD_DIR="/tmp/build"
OUTPUT_DIR="/output"
INPUT_FILE="/input/data.json"
LATEX_PROGRAM="${LATEX_PROGRAM:-latexmk}"
LATEX_ARGS="${LATEX_ARGS:--pdf}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            DATA_SOURCE="--file $INPUT_FILE"
            shift 2
            ;;
        -u|--url)
            DATA_SOURCE="--url $2"
            shift 2
            ;;
        *)
            DATA_SOURCE="$@"
            break
            ;;
    esac
done

if [ -z "$DATA_SOURCE" ]; then
    echo "Error: No data source provided. Use -f/--file or -u/--url."
    exit 1
fi

echo "Step 1: Filling template with data..."
echo "Data source: $DATA_SOURCE"
echo ""

cd /app
mkdir -p ${BUILD_DIR}

source .config
export BUILD_DIR
export CV_FILE_NAME
python3 scripts/fill_template.py $DATA_SOURCE

if [ $? -ne 0 ]; then
    echo "Error: Failed to fill template"
    exit 1
fi

echo ""
echo "Step 2: Compiling LaTeX..."
echo "LaTeX program: $LATEX_PROGRAM"
echo "LaTeX args: $LATEX_ARGS"
echo "Source directory: $BUILD_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

cd $BUILD_DIR
mkdir -p $OUTPUT_DIR

set -o allexport
source .config
set +o allexport

$LATEX_PROGRAM $LATEX_ARGS main.tex
cp main.pdf $OUTPUT_DIR/main.pdf

if [ $? -ne 0 ]; then
    echo "Error: LaTeX compilation failed"
    exit 1
fi

echo ""
echo "=== CV Generation Complete ==="
echo "Output: $OUTPUT_DIR/main.pdf"

# If RESULT_FILENAME is set, rename the output
if [ ! -z "$RESULT_FILENAME" ]; then
    echo "Renaming to: $OUTPUT_DIR/${RESULT_FILENAME}.pdf"
    mv $OUTPUT_DIR/main.pdf $OUTPUT_DIR/${RESULT_FILENAME}.pdf
fi

echo ""
echo "Done!"
