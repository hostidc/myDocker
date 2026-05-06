FROM python:3.11-slim

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
