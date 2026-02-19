# Single-stage Dockerfile for CV generation with Python and LaTeX
FROM texlive/texlive:latest

# Install curl (Python 3.13 is already included in texlive image)
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install uv package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy Python dependencies
COPY pyproject.toml uv.lock ./

# Install Python dependencies
RUN uv sync --no-dev --frozen --no-cache

# Copy project files
COPY scripts/ ./scripts/
COPY template/ ./template/
COPY .config ./

# Set environment variables
ENV PYTHONPATH=/app/.venv/lib/python3.13/site-packages
ENV PATH=/app/.venv/bin:$PATH

# Entry point script
COPY containers/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default command: fill template and compile
ENTRYPOINT ["/entrypoint.sh"]
CMD ["--file", "data.json"]
