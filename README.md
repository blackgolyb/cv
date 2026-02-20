# CV Generator

A simple tool to generate professional CV/Resume PDFs from JSON data using LaTeX templates and Docker.

## Requirements

- Docker
- Make

## Quick Start

### 1. Prepare Your Data

Create or edit `data.json` with your CV information. Use `example.json` as a template

### 2. Configure Settings (Optional)

Edit `.config` file if needed:

```sh
# Choose theme
THEME=base

# Output filename pattern
CV_FILE_NAME=CV_{lastName}_{firstName}_{position}

# Use local file or remote URL
# DATA_FILE=data.json
DATA_URL=https://example.com/data.json
```

### 3. Generate Your CV

```sh
# Build everything (first time to build the Docker image)
make full

# Rebuild CV after data changes
make
```

Your PDF will be in the `build/` directory.

That's it!
