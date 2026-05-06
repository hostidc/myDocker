# ============================================
# 基于 python:3.11-slim，支持 MyBinder 平台部署
# ============================================
FROM python:3.11-slim

# MyBinder 兼容参数
ARG NB_USER=jovyan
ARG NB_UID=1000

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    USER=${NB_USER} \
    HOME=/home/${NB_USER}

# ============================================
# 第一阶段：安装系统依赖和 Python 包
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* && \
    # 下载并安装 MinIO Server
    wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio && \
    chmod +x /usr/local/bin/minio && \
    # 创建 MinIO 数据目录
    mkdir -p /data/minio && \
    # 安装 Python 包
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    notebook \
    jupyterlab \
    jupyterhub \
    uvicorn \
    fastapi \
    alembic \
    pymongo \
    psycopg2-binary \
    redis \
    minio \
    chromadb

# ============================================
# 第二阶段：创建非 root 用户（MyBinder 要求）
# ============================================
RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

# ============================================
# 第三阶段：设置工作目录并复制文件
# ============================================
WORKDIR ${HOME}/work
COPY . ${HOME}/work
RUN chown -R ${NB_USER}:${NB_USER} ${HOME}

# 创建 MinIO 数据目录并设置权限
RUN mkdir -p /data/minio && \
    chown -R ${NB_USER}:${NB_USER} /data

# ============================================
# 第四阶段：切换用户
# ============================================
USER ${USER}

# 暴露端口：Jupyter Lab (8888) + MinIO API (9000) + MinIO Console (9001)
EXPOSE 8888 9000 9001

# 使用启动脚本同时运行 Jupyter Lab 和 MinIO
CMD sh -c "minio server /data/minio --address ':9000' --console-address ':9001' &\
           sleep 2 && \
           echo 'MinIO started on port 9000, Console on port 9001' && \
           exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/home/jovyan/work --ServerApp.token='' --ServerApp.password='' --ServerApp.open_browser=False --Application.log_level=INFO"
