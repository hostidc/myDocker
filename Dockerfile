FROM rocker/tidyverse:4.5

# 安装系统依赖和 Redis
RUN apt-get update && apt-get install -y --no-install-recommends \
    redis-server

# 创建 Redis 数据目录并设置权限
RUN mkdir -p /data/redis && \
    chown -R nobody:nogroup /data/redis

# 暴露 Redis 默认端口
EXPOSE 6379

# 启动 Redis 服务和 R 环境
CMD ["sh", "-c", "redis-server --daemonize yes --dir /data/redis && exec bash"]
