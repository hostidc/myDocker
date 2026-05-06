# ============================================
# 基于 Ubuntu 22.04，支持 MyBinder 平台部署
# ============================================
FROM ubuntu:22.04

# MyBinder 兼容参数
ARG NB_USER=jovyan
ARG NB_UID=1000

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHON_VERSION=3.11 \
    NODE_VERSION=20 \
    MONGODB_VERSION=5.0.32 \
    POSTGRES_VERSION=15 \
    REDIS_VERSION=7.2 \
    MINIO_VERSION=RELEASE.2025-09-07T16-13-09Z \
    NB_USER=${NB_USER} \
    NB_UID=${NB_UID} \
    HOME=/home/${NB_USER}

# ============================================
# 第一阶段：安装系统依赖和基础工具
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    ca-certificates \
    openssl \
    supervisor \
    nginx \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 第二阶段：创建非 root 用户（MyBinder 要求）
# ============================================
RUN groupadd -r ${NB_USER} && \
    useradd -r -g ${NB_USER} -d ${HOME} -s /bin/bash ${NB_USER} && \
    mkdir -p ${HOME}/work && \
    chown -R ${NB_USER}:${NB_USER} ${HOME}

# ============================================
# 第三阶段：安装 Python 依赖包
# ============================================
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
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
    chromadb && \
    # 确保 jupyter 命令在全局 PATH 中可用
    ln -sf /usr/local/bin/jupyter /usr/bin/jupyter || true && \
    ln -sf /usr/local/bin/jupyter-lab /usr/bin/jupyter-lab || true

# ============================================
# 第四阶段：确保 python3 和 jupyter 命令可用（必须在 USER 之前）
# ============================================
RUN ln -sf $(which python3) /usr/local/bin/python3 && \
    # 验证 jupyter 是否可执行
    which jupyter && jupyter --version

# ============================================
# 第五阶段：切换用户并设置工作目录
# ============================================
USER ${NB_USER}
WORKDIR /home/${NB_USER}/work

# ============================================
# 第六阶段：复制应用文件
# ============================================
COPY --chown=${NB_USER}:${NB_USER} . /home/${NB_USER}/work/

# 暴露 Jupyter Lab 端口
EXPOSE 8888

# 使用 exec 直接启动 Jupyter Lab（避免 shell 包装）
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--notebook-dir=/home/jovyan/work", "--ServerApp.token=''", "--ServerApp.password=''", "--ServerApp.open_browser=False", "--Application.log_level=INFO"]
