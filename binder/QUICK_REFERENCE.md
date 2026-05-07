# MyBinder 快速参考卡片

## 🎯 一键启动

```
https://mybinder.org/v2/gh/YOUR_USERNAME/myDocker/main?urlpath=lab
```

将 `YOUR_USERNAME` 替换为你的 GitHub 用户名

## 📁 重要路径

| 用途 | 路径 |
|------|------|
| 工作目录 | `/home/jovyan/work` |
| 示例 Notebook | `/home/jovyan/work/binder/notebooks/` |
| Python 包安装 | `!pip install package-name` |

## 🔧 常用命令

### 在 Notebook 中执行

```python
# 安装额外包
!pip install package-name

# 查看当前目录
!pwd

# 列出文件
!ls -la

# 查看环境变量
import os
print(os.environ.get('BINDER_LAUNCH_URL'))
```

### 数据库连接字符串

```python
# MongoDB
mongodb://localhost:27017/

# PostgreSQL
postgresql://postgres:aiproxy@localhost:5432/postgres

# Redis
redis://:mypassword@localhost:6379

# MinIO
Endpoint: localhost:9000
Access Key: minioadmin
Secret Key: minioadmin
```

## ⚡ 快速测试

### 测试 Python 环境
```python
import sys
print(sys.version)
```

### 测试文件系统
```python
import os
os.makedirs('/home/jovyan/work/test', exist_ok=True)
with open('/home/jovyan/work/test/hello.txt', 'w') as f:
    f.write('Hello Binder!')
```

### 测试网络
```python
import socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
result = sock.connect_ex(('localhost', 80))
print("Port 80:", "Open" if result == 0 else "Closed")
sock.close()
```

## 🚫 限制提醒

- ⏱️ **会话超时**: 10 分钟无活动
- 💾 **内存限制**: ~2GB RAM
- 💻 **CPU**: 共享资源
- 💿 **存储**: 临时，关闭后丢失
- 🌐 **网络**: 部分端口可能受限

## 📚 学习资源

- [JupyterLab 文档](https://jupyterlab.readthedocs.io/)
- [MyBinder 指南](https://mybinder.readthedocs.io/)
- [FastGPT 文档](https://fastgpt.in/)

## 🆘 遇到问题？

1. **构建失败**: 检查 `binder/environment.yml` 语法
2. **无法加载**: 刷新浏览器或改用 `/tree` 路径
3. **数据丢失**: 记得下载到本地或推送到 GitHub
4. **性能慢**: MyBinder 资源有限，建议本地部署

---

**提示**: 将此文件保存到书签，方便随时查阅！
