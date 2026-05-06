# ============================================
# 基于 python:3.11-slim，支持 MyBinder 平台部署
# 内置：JupyterLab + MinIO + Redis + MongoDB（副本集）
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
    MONGO_USER=myusername \
    MONGO_PASS=mypassword \
    MONGO_DB=fastgpt \
    MONGO_PORT=27017

# ============================================
# 安装系统依赖 + openssh-client（已修复）
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget ca-certificates git iproute2 procps net-tools dnsutils \
    tree jq vim-tiny nano less unzip zip tar gzip \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 安装 MinIO
# ============================================
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio && \
    chmod +x /usr/local/bin/minio

# ============================================
# 安装 Redis 便携版
# ============================================
RUN git clone https://github.com/cppxaxa/redis-portable-linux /tmp/redis && \
    cp /tmp/redis/redis-server /usr/local/bin/ && \
    cp /tmp/redis/redis-cli /usr/local/bin/ && \
    chmod +x /usr/local/bin/redis-server /usr/local/bin/redis-cli && \
    rm -rf /tmp/redis

# ============================================
# 安装 mongosh（新版 MongoDB 客户端）
# ============================================
RUN wget https://downloads.mongodb.com/compass/mongosh-2.2.15-linux-x64.tgz -O /tmp/mongosh.tgz && \
    tar zxf /tmp/mongosh.tgz -C /tmp && \
    cp /tmp/mongosh-2.2.15-linux-x64/bin/mongosh /usr/local/bin/ && \
    chmod +x /usr/local/bin/mongosh && \
    rm -rf /tmp/mongosh*

# ============================================
# 安装 Python 依赖
# ============================================
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
RUN mkdir -p ${MINIO_DIR} ${REDIS_DIR} /data/db /data/mongodb && \
    mkdir -p ${HOME}/work ${HOME}/bin && \
    chown -R ${NB_USER}:${NB_USER} ${HOME} /data

# ============================================
# 工作目录
# ============================================
WORKDIR ${HOME}/work
COPY . ${HOME}/work

# 切换普通用户
USER ${USER}

# 暴露端口
EXPOSE 8888 9000 9001 6379 27017

# ============================================
# 启动命令：后台启动全部服务 + 前台启动 Jupyter
# ============================================
CMD ["sh", "-c", "\
# ---------- 1. 启动 Redis ---------- \
redis-server --port ${REDIS_PORT} --requirepass ${REDIS_PASSWORD} --daemonize yes \
\n\
# ---------- 2. 启动 MinIO ---------- \
minio server ${MINIO_DIR} --console-address \":9001\" > minio.log 2>&1 & \
\n\
# ---------- 3. 启动 MongoDB 副本集 ---------- \
mkdir -p ./data/db \
echo \"mysecretkey\" > ./mongodb.key \
chmod 600 ./mongodb.key \
\n\
mongod --dbpath ./data/db --port ${MONGO_PORT} --bind_ip 0.0.0.0 --keyFile ./mongodb.key --replSet rs0 --auth > mongodb.log 2>&1 & \
sleep 3 \
\n\
# 初始化副本集 \
mongosh --port ${MONGO_PORT} --eval \"rs.initiate({_id:'rs0',members:[{_id:0,host:'127.0.0.1:27017'}]})\" \
sleep 5 \
\n\
# 创建管理员账号 \
mongosh --port ${MONGO_PORT} --eval \"db.getSiblingDB('admin').createUser({user:'${MONGO_USER}',pwd:'${MONGO_PASS}',roles:['root']})\" \
sleep 1 \
\n\
# 测试连通性 \
mongosh \"mongodb://${MONGO_USER}:${MONGO_PASS}@127.0.0.1:${MONGO_PORT}/admin?authSource=admin&replicaSet=rs0\" --eval \"db.adminCommand('ping')\" \
\n\
# ---------- 4. 启动 JupyterLab ---------- \
exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser \
--ServerApp.token='' --ServerApp.password='' \
--ServerApp.allow_origin='*' \
--notebook-dir=${HOME}/work \
"]
