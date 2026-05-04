FROM rocker/binder:4.1.2
LABEL maintainer='Ben Marwick <benmarwick@gmail.com>'
USER root
COPY . ${HOME}
RUN chown -R ${NB_USER} ${HOME}
USER ${NB_USER}
