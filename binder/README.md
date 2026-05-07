# FastGPT on MyBinder

本目录包含在 [MyBinder](https://mybinder.org/) 平台上运行 FastGPT 所需的配置文件。

## 🚀 快速开始

### 在 MyBinder 上启动

点击以下按钮在 MyBinder 上启动 FastGPT 环境：

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/YOUR_USERNAME/myDocker/main?urlpath=lab)

> **注意**: 请将 `YOUR_USERNAME` 替换为你的 GitHub 用户名

### 本地测试 Binder 配置

```bash
# 使用 repo2docker 本地测试
pip install repo2docker
repo2docker .
```

## 📋 环境说明

### 已安装的工具

- **Python 3.11**: 主要编程语言
- **JupyterLab**: 交互式开发环境
- **Jupyter Notebook**: 传统笔记本界面
- **FastAPI + Uvicorn**: Web 框架
- **数据库客户端**: pymongo, psycopg2-binary, redis
- **向量数据库**: chromadb
- **对象存储**: minio

### 工作目录

- **默认工作区**: `/home/jovyan/work`
- 所有 Notebook 和代码文件应保存在此目录下

## ⚙️ 配置选项

### 自定义 Python 版本

编辑 `environment.yml` 文件中的 `python=3.11` 行

### 添加新的依赖包

在 `environment.yml` 的 `dependencies` 部分添加：

```yaml
dependencies:
  - pip:
    - your-package-name
```

## 🔧 故障排查

### 构建失败

1. 检查 `environment.yml` 语法是否正确
2. 确保所有包名称拼写正确
3. 查看 Binder 构建日志获取详细错误信息

### Jupyter Lab 无法启动

1. 确认端口 8888 未被占用
2. 检查浏览器是否阻止了弹出窗口
3. 尝试使用 Jupyter Notebook 替代：将 URL 中的 `lab` 改为 `tree`

## 📝 注意事项

- MyBinder 会话是临时的，关闭浏览器后数据会丢失
- 重要数据请下载到本地保存
- 会话超时时间通常为 10 分钟无活动
- 内存限制约为 2GB，CPU 资源有限

## 🔗 相关链接

- [MyBinder 官方文档](https://mybinder.readthedocs.io/)
- [repo2docker 文档](https://repo2docker.readthedocs.io/)
- [JupyterLab 文档](https://jupyterlab.readthedocs.io/)
