# ============================================
# 基于 python:3.11-slim，支持 MyBinder 平台部署
# 内置：JupyterLab + MinIO（可网页访问控制台）
# ============================================
FROM python:3.11-slim

# MyBinder 兼容参数
ARG NB_USER=jovyan
ARG NB_UID=1000

# 环境变量（含 MinIO 默认账号密码）
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    USER=${NB_USER} \
    HOME=/home/${NB_USER} \
    MINIO_ROOT_USER=admin \
    MINIO_ROOT_PASSWORD=12345678 \
    MINIO_DIR=/data/minio

# ============================================
# 安装系统依赖 + MinIO + Python 工具包
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget ca-certificates git iproute2 procps net-tools dnsutils \
    tree jq vim-tiny nano less unzip zip tar gzip \
    && rm -rf /var/lib/apt/lists/*

# 安装 MinIO（linux/amd64 版本，兼容 Binder）
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio && \
    chmod +x /usr/local/bin/minio

# 安装 Python 依赖 + Jupyter 代理
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    notebook jupyterlab jupyter-server-proxy \
    uvicorn fastapi alembic pymongo psycopg2-binary redis minio chromadb

# ============================================
# ✅ 修复：新版 Jupyter 启用 jupyter-server-proxy 的正确命令
# ============================================
RUN jupyter server extension enable --user jupyter_server_proxy

# ============================================
# 创建 Binder 必须的普通用户
# ============================================
RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

# ============================================
# 创建目录并授权（解决权限问题）
# ============================================
RUN mkdir -p ${MINIO_DIR} && \
    mkdir -p ${HOME}/work && \
    chown -R ${NB_USER}:${NB_USER} ${HOME} /data

# ============================================
# 工作目录
# ============================================
WORKDIR ${HOME}/work
COPY . ${HOME}/work

# ============================================
# 切换普通用户
# ============================================
USER ${USER}

# 暴露端口
EXPOSE 8888 9000 9001

# ============================================
# 启动命令：后台跑 MinIO + 前台 JupyterLab
# ============================================
CMD sh -c " \
minio server ${MINIO_DIR} --address ':9000' --console-address ':9001' & \
sleep 3 && \
echo '===================================================' && \
echo '✅ MinIO 已启动' && \
echo '🔑 用户名: '${MINIO_ROOT_USER} && \
echo '🔑 密码: '${MINIO_ROOT_PASSWORD} && \
echo '🖥  MinIO 控制台: http://localhost:9001' && \
echo '🌍 Binder 中访问: /proxy/9001' && \
echo '===================================================' && \
exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser \
--ServerApp.token='' --ServerApp.password='' \
--ServerApp.allow_origin='*' \
--notebook-dir=${HOME}/work \
"
