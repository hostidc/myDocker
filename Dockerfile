# Multi-stage build for RAG Web UI - Single Container Architecture
# Modified for MyBinder compatibility
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    PYTHONUNBUFFERED=1 \
    NB_USER=jovyan \
    NB_UID=1000 \
    USER=jovyan \
    HOME=/home/jovyan

# Create non-root user with UID 1000 (required by Binder)
RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    build-essential \
    supervisor \
    nginx \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Install MySQL Server
RUN apt-get update && apt-get install -y \
    mysql-server \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Configure MySQL
RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld

# Install Python 3.11
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3.11 /usr/bin/python \
    && ln -sf /usr/bin/python3.11 /usr/bin/python3

# Install pip
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Install Jupyter Notebook and JupyterLab (required by Binder)
RUN python3 -m pip install --no-cache-dir notebook jupyterlab jupyterhub

# Copy repository contents to HOME directory
COPY . ${HOME}

# Change ownership to the non-root user
USER root
RUN chown -R ${NB_UID}:${NB_UID} ${HOME}

# Switch to non-root user
USER ${NB_USER}

# Expose ports
EXPOSE 3306 80 3000 8000 9000 9001 8888

# Set working directory
WORKDIR ${HOME}

# Default command will be overridden by Binder
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]
