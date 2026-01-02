# ------- Stage 1: Base Setup (Debian Slim) -----
FROM python:3.12-slim AS python_base

# Python optimizations
ENV PYTHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1

# Install PostgreSQL client libraries (required for psycopg2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ------ Stage 2: Builder ------
FROM python_base AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# ------ Stage 3: Dev Environment ------
FROM python_base AS dev
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Add common debug tools for local troubleshooting
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    vim \
    wget \
    dnsutils \
    netcat-openbsd \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app"

COPY pyproject.toml uv.lock ./
COPY app ./app
COPY main.py ./

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project

CMD ["uv", "run", "main.py"]

# -------- Stage 4: Production (The Tiny Image) ------
FROM python_base AS prod

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

COPY --from=builder /app/.venv /app/.venv
COPY app ./app
COPY main.py ./

# Create cache directory with proper permissions
RUN mkdir -p /app/.cache/uv && chown -R appuser:appuser /app

USER appuser

ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app/"

CMD ["uv", "run", "main.py"]
