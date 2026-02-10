# Multi-stage build for optimized container
FROM python:3.11-alpine AS builder

# Build-time configuration (VERSION is optional - if not provided, installs latest)
ARG VERSION
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install build dependencies and mnamer package
# If VERSION is set, install specific version; otherwise install latest
RUN pip install --upgrade pip setuptools wheel && \
    if [ -n "$VERSION" ]; then \
        pip install "mnamer==${VERSION}"; \
    else \
        pip install mnamer; \
    fi

# Runtime stage
FROM python:3.11-alpine

# User/Group configuration via build args with defaults
ARG USER_ID=1000
ARG GROUP_ID=1000

# Runtime configuration
ENV PYTHONUNBUFFERED=1 \
    MNAMER_CONFIG_PATH=/config/.mnamer-v2.json \
    MEDIA_PATH=/media \
    PUID=${USER_ID} \
    PGID=${GROUP_ID}

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY mnamer_entrypoint.py /usr/local/bin/mnamer-entrypoint.py

# Create non-privileged user and directories with configurable UID/GID
RUN addgroup -g ${GROUP_ID} mediauser && \
    adduser -u ${USER_ID} -G mediauser -s /bin/sh -D mediauser && \
    mkdir -p /media /config && \
    chown -R mediauser:mediauser /media /config

# Switch to non-privileged user
USER mediauser

# Set working directory
WORKDIR /media

# Health check to verify mnamer is available
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -m mnamer --version || exit 1

# Default command with batch processing
ENTRYPOINT ["python", "/usr/local/bin/mnamer-entrypoint.py"]
CMD ["--batch", "/media"]
