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

# ============================================
# 第四阶段：切换用户
# ============================================
USER ${USER}

# 暴露 Jupyter Lab 端口
EXPOSE 8888

# 使用 JSON 格式 CMD 直接启动 Jupyter Lab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--notebook-dir=/home/jovyan/work", "--ServerApp.token=''", "--ServerApp.password=''", "--ServerApp.open_browser=False", "--Application.log_level=INFO"]
