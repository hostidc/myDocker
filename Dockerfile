# ============================================
# 基于 python:3.11-slim，支持 MyBinder 平台部署
# 内置：JupyterLab + MinIO + Redis + MongoDB
# ============================================
FROM python:3.11-slim

# MyBinder 兼容参数
ARG NB_USER=jovyan
ARG NB_UID=1000

# 环境变量（含 MinIO / Redis / MongoDB 默认配置）
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    USER=${NB_USER} \
    HOME=/home/${NB_USER} \
    MINIO_ROOT_USER=minioadmin \
    MINIO_ROOT_PASSWORD=minioadmin \
    MINIO_DIR=/data/minio \
    REDIS_PORT=6379 \
    REDIS_PASSWORD=mypassword \
    REDIS_DIR=/data/redis \
    MONGO_PORT=27017 \
    MONGO_DIR=/data/mongodb

# ============================================
# 安装系统依赖 + MinIO + Redis 便携版 + Python
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget ca-certificates git iproute2 procps net-tools dnsutils \
    tree jq vim-tiny nano less unzip zip tar gzip \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# 安装 MinIO
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio && \
    chmod +x /usr/local/bin/minio

# 安装 Redis 便携版
RUN git clone https://github.com/cppxaxa/redis-portable-linux /tmp/redis && \
    cp /tmp/redis/redis-server /usr/local/bin/ && \
    cp /tmp/redis/redis-cli /usr/local/bin/ && \
    chmod +x /usr/local/bin/redis-server /usr/local/bin/redis-cli && \
    rm -rf /tmp/redis

# 安装 MongoDB 5.0（便携版二进制文件）
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then MONGO_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then MONGO_ARCH="aarch64"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi && \
    echo "Installing MongoDB for architecture: $MONGO_ARCH" && \
    wget https://fastdl.mongodb.org/linux/mongodb-linux-${MONGO_ARCH}-ubuntu2204-5.0.32.tgz -O /tmp/mongodb.tgz && \
    tar -xzf /tmp/mongodb.tgz -C /tmp/ && \
    cp /tmp/mongodb-linux-${MONGO_ARCH}-ubuntu2204-5.0.32/bin/mongod /usr/local/bin/ && \
    cp /tmp/mongodb-linux-${MONGO_ARCH}-ubuntu2204-5.0.32/bin/mongosh /usr/local/bin/ && \
    chmod +x /usr/local/bin/mongod /usr/local/bin/mongosh && \
    rm -rf /tmp/mongodb* && \
    mongod --version && \
    mongosh --version

# 安装 Python 依赖
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    notebook jupyterlab jupyter-server-proxy \
    uvicorn fastapi alembic pymongo psycopg2-binary redis minio chromadb

# 启用 Jupyter 代理
RUN jupyter server extension enable --user jupyter_server_proxy

# 创建普通用户（Binder 必须）
RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

# 创建目录并授权
RUN mkdir -p ${MINIO_DIR} ${REDIS_DIR} ${MONGO_DIR} && \
    mkdir -p ${HOME}/work && \
    chown -R ${NB_USER}:${NB_USER} ${HOME} /data

# 工作目录
WORKDIR ${HOME}/work
COPY . ${HOME}/work

# 切换普通用户
USER ${USER}

# 暴露端口
EXPOSE 8888 9000 9001 6379 27017

# ============================================
# 启动命令（启动 JupyterLab + MongoDB）
# ============================================
CMD ["sh", "-c", "\
echo '=== Starting services ===' && \
echo 'Starting MongoDB...' && \
mkdir -p ${MONGO_DIR} && \
mongod --dbpath ${MONGO_DIR} --port ${MONGO_PORT} --bind_ip_all --fork --logpath /tmp/mongod.log && \
sleep 2 && \
if pgrep mongod > /dev/null; then \
echo '✓ MongoDB is running on port ${MONGO_PORT}'; \
else \
echo '✗ MongoDB failed to start. Check /tmp/mongod.log for details'; \
cat /tmp/mongod.log; \
exit 1; \
fi && \
exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser \
--ServerApp.token='' --ServerApp.password='' \
--ServerApp.allow_origin='*' \
--notebook-dir=${HOME}/work \
"]
