# Multi-stage build for RAG Web UI - Single Container Architecture
FROM ubuntu:22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    PYTHONUNBUFFERED=1

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

# Expose ports
EXPOSE 3306 80 3000 8000 9000 9001
