# GÉRARD Multi-Agent Orchestrator
# Optimized for ARM64 (Xiaomi Pad 6) and x86_64
# Production-ready containerized deployment

FROM python:3.11-slim-bullseye

# Metadata
LABEL name="gerard-orchestrator" \
      version="1.0.0" \
      description="Multi-Agent Autonomous Orchestrator" \
      architecture="arm64,amd64" \
      maintainer="TipTopTap <contact@tiptoptap.dev>"

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive \
    APP_HOME=/app \
    APP_USER=gerard

# Create non-root user for security
RUN groupadd -r $APP_USER && \
    useradd -r -g $APP_USER -d $APP_HOME -s /bin/bash $APP_USER

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    sqlite3 \
    redis-tools \
    build-essential \
    pkg-config \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create application directory
RUN mkdir -p $APP_HOME && chown -R $APP_USER:$APP_USER $APP_HOME
WORKDIR $APP_HOME

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY --chown=$APP_USER:$APP_USER . .

# Create necessary directories
RUN mkdir -p {\
    data/{db,logs,artifacts,cache,reports},\
    src/{core,agents,utils,api},\
    config,\
    tests/{unit,integration},\
    scripts\
    } && \
    chown -R $APP_USER:$APP_USER .

# Set executable permissions
RUN chmod +x setup.sh quick_gerard.py && \
    chmod +x scripts/*.sh 2>/dev/null || true

# Initialize database
RUN sqlite3 data/db/gerard.db "CREATE TABLE IF NOT EXISTS agents (id INTEGER PRIMARY KEY, name TEXT, status TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);" && \
    sqlite3 data/db/gerard.db "CREATE TABLE IF NOT EXISTS tasks (id INTEGER PRIMARY KEY, agent_name TEXT, task_description TEXT, status TEXT, result TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, completed_at TIMESTAMP);" && \
    chown -R $APP_USER:$APP_USER data/

# Switch to non-root user
USER $APP_USER

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import sqlite3; conn = sqlite3.connect('data/db/gerard.db'); conn.execute('SELECT 1'); conn.close()" || exit 1

# Expose ports
EXPOSE 8000 8001 8002

# Default command
CMD ["python", "quick_gerard.py"]

# Alternative commands:
# For API server: CMD ["uvicorn", "src.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
# For orchestrator: CMD ["python", "src/main.py"]
# For interactive demo: CMD ["python", "quick_gerard.py"]
