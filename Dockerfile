# Multi-stage build for RAG Web UI - Single Container Architecture
FROM ubuntu:22.04 AS base

# Install MySQL Server
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    mysql-server \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Configure MySQL
RUN mkdir -p /var/run/mysqld && \
    chown mysql:mysql /var/run/mysqld

# Expose MySQL port
EXPOSE 3306
