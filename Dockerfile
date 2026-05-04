FROM python:3.11-slim

# 安装必要的系统工具(包括 passwd)
RUN apt-get update && \
    apt-get install -y --no-install-recommends passwd sudo && \
    rm -rf /var/lib/apt/lists/*

# 设置 root 密码 (仅用于开发测试环境)
RUN echo 'root:root123' | chpasswd

# install the notebook package
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir notebook jupyterlab jupyterhub

# create user with a home directory
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

WORKDIR ${HOME}
COPY . ${HOME}
RUN chown -R ${NB_USER}:${NB_USER} ${HOME}

USER ${USER}
