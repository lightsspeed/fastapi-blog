# =====================
# Multi-stage Dockerfile
# =====================

# ---------- Stage 1: Builder ----------
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install --no-cache-dir --prefix=/install -r requirements.txt


# ---------- Stage 2: Runtime ----------
FROM python:3.12-slim AS runtime

# Security: create a non-root user
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application source
COPY fastapi_blog/ ./fastapi_blog/

# Set ownership
RUN chown -R appuser:appgroup /app

# Create tests directory for pytest
RUN mkdir -p /app/tests

USER appuser

# Expose application port
EXPOSE 8000

# Health check (also used by Docker Compose / local testing)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Start the application
CMD ["python", "-m", "uvicorn", "fastapi_blog.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
