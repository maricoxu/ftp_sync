# 🚀 ProFTPD SFTP同步工具 - 快速入门指南

## 5分钟快速部署

### 第一步：环境准备
```bash
# 确保你有管理员权限的Linux环境（推荐Ubuntu 20.04+）
# 检查系统版本
lsb_release -a

# 如果在Docker容器中，确保容器有必要权限
docker --version
```

### 第二步：下载和部署
```bash
# 1. 将项目文件上传到服务器（任意目录）
cd /home/Code  # 或任意你选择的目录
git clone <your-repo> ftp_sync  # 或直接上传文件
cd ftp_sync

# 2. 给脚本执行权限
chmod +x *.sh
```

### 第三步：智能初始化配置

🎯 **新特性**: 现在支持自定义 FTP 工作目录路径！

#### 方法一：交互式配置（推荐）
```bash
# 运行初始化脚本
bash ./init.sh

# 会出现交互式界面：
# 🎯 === ProFTPD 服务器初始化配置 ===
# 📂 请设置 FTP 服务器的工作目录（这将是VS Code同步的目标路径）
#    默认路径: /home/Code
#
# 选项：
#   1. 直接按 Enter 使用默认路径
#   2. 输入自定义的绝对路径
#
# 请输入FTP工作目录路径 [默认: /home/Code]: 
```

**操作示例**：
- 直接按 `Enter` 使用默认路径 `/home/Code`
- 或者输入自定义路径，如 `/var/www/myproject`

#### 方法二：命令行参数
```bash
# 直接指定路径
bash ./init.sh /var/www/myproject

# 或者使用默认路径
bash ./init.sh /home/Code
```

#### 预期输出（彩色提示）：
```
✅ 使用默认路径: /home/Code  (或你指定的路径)
✅ 确保目录 /home/Code 存在
✅ 用户 'ftpuser' 创建成功
🔐 已设置用户 ftpuser 的密码
📁 已设置所有权和权限
🎉 初始化设置完成！
```

### 第四步：启动服务
```bash
# 启动FTP服务器
bash ./start.sh

# 验证服务状态
ps aux | grep proftpd
netstat -anpt | grep 8021
```

### 第五步：VS Code配置
在你的VS Code项目中创建 `.vscode/sftp.json`：

```json
{
    "name": "我的开发服务器",
    "host": "your-server-ip",        // 👈 改为你的服务器IP
    "protocol": "ftp",
    "port": 8021,
    "username": "ftpuser",
    "password": "ftp123",
    "remotePath": "/home/Code",
    "uploadOnSave": true,
    "passive": true,
    "ignore": [".git/**", "node_modules/**", "*.log"]
}
```

### 第六步：测试连接
```bash
# 在VS Code中按 Ctrl+Shift+P
# 输入：SFTP: Upload Project
# 或者：SFTP: List Remote
```

---

## 🎯 常用场景快速配置

### 场景1：多环境开发（推荐）
```json
{
    "name": "默认",
    "protocol": "ftp",
    "port": 8021,
    "username": "ftpuser", 
    "password": "ftp123",
    "uploadOnSave": true,
    "passive": true,
    "profiles": {
        "dev": {
            "name": "开发环境",
            "host": "dev-server.com",
            "remotePath": "/home/Code/dev"
        },
        "prod": {
            "name": "生产环境", 
            "host": "prod-server.com",
            "remotePath": "/home/Code/prod",
            "uploadOnSave": false
        }
    },
    "defaultProfile": "dev"
}
```
**切换环境**: `Ctrl+Shift+P` → `SFTP: Set Profile`

### 场景2：多项目工作区
```json
[
    {
        "name": "前端项目",
        "context": "./frontend",
        "host": "server.com",
        "protocol": "ftp",
        "port": 8021,
        "username": "ftpuser",
        "password": "ftp123",
        "remotePath": "/home/Code/frontend"
    },
    {
        "name": "后端项目",
        "context": "./backend",
        "host": "server.com",
        "protocol": "ftp", 
        "port": 8021,
        "username": "ftpuser",
        "password": "ftp123",
        "remotePath": "/home/Code/backend"
    }
]
```

### 场景3：高性能配置
```json
{
    "name": "高性能开发",
    "host": "your-server.com",
    "protocol": "ftp",
    "port": 8021,
    "username": "ftpuser",
    "password": "ftp123",
    "remotePath": "/home/Code",
    "uploadOnSave": true,
    "passive": true,
    "concurrency": 4,
    "connectTimeout": 30000,
    "retryOnError": true,
    "retryCount": 3,
    "ignore": [
        ".git/**",
        "node_modules/**", 
        "dist/**",
        "*.log",
        "*.tmp"
    ],
    "watcher": {
        "files": "src/**/*.{js,ts,vue,css}",
        "autoUpload": true,
        "autoDelete": false
    }
}
```

---

## 🔧 故障快速诊断

### 问题1：连接失败
```bash
# 检查服务状态
ps aux | grep proftpd
netstat -anpt | grep 8021

# 重启服务
bash ./stop.sh
bash ./start.sh

# 查看日志
tail -f var/proftpd.system.log
```

### 问题2：上传失败
```bash
# 检查权限
ls -la /home/Code
id ftpuser

# 重新设置权限
bash ./init.sh
```

### 问题3：防火墙问题
```bash
# 检查端口是否开放
telnet your-server-ip 8021

# 配置防火墙（Ubuntu）
sudo ufw allow 8021
sudo ufw allow 8000:8999/tcp
```

---

## 📋 常用命令速查

### 服务管理
```bash
bash ./start.sh          # 启动服务
bash ./stop.sh           # 停止服务
bash ./init.sh           # 重新初始化
```

### 日志查看
```bash
tail -f var/proftpd.system.log     # 系统日志
tail -f var/proftpd.transfer.log   # 传输日志
```

### 权限修复
```bash
chown -R ftpuser:ftpuser /home/Code
chmod -R 755 /home/Code
```

### VS Code SFTP命令
- `SFTP: Config` - 创建配置
- `SFTP: Upload` - 上传文件
- `SFTP: Download` - 下载文件
- `SFTP: Sync Local -> Remote` - 同步到远程
- `SFTP: List` - 列出远程文件

---

## 🎉 完成！

现在你已经成功配置了ProFTPD服务器和VS Code SFTP同步！

**下一步建议**：
1. 📖 阅读完整的[README.md](./README.md)了解更多高级功能
2. 🔒 查看安全配置建议
3. 🚀 探索多服务器配置方案
4. 📊 了解性能优化技巧

**需要帮助？**
- 查看[CHANGELOG.md](./CHANGELOG.md)了解版本特性
- 检查日志文件进行故障排除
- 确保按照文档步骤操作

祝你使用愉快！ 🎊