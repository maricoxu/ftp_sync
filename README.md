# ProFTPD 服务器：用于 VS Code SFTP 同步

本项目提供了一个预配置的 ProFTPD 服务器设置，旨在 Docker 容器内部运行。它通过 FTP 协议，简化了本地 VS Code 工作区与远程开发机器之间的文件同步。

🎆 **项目优化亮点**:
- 🇨🇳 **中文友好**: 默认中文文档，中文界面提示
- 🎨 **视觉增强**: 彩色高亮提示，操作状态一目了然
- 📁 **通用性优化**: 无硬编码路径，支持任意部署位置
- 🔀 **多服务器支持**: 详细的多 SFTP 配置说明

服务器配置为使用一个专用的 FTP 用户 (`ftpuser`)，其主目录在远程机器上设置为 `/home/Code`。这个 `/home/Code` 目录也应作为你的 VS Code SFTP 插件中 `remotePath` 的目标。

## 主要特性

*   **专用 FTP 用户**: 使用非 root 用户 (`ftpuser`) 进行 FTP 访问。
*   **目标同步目录**: 配置为同步到 `/home/Code`。
*   **自动化安装**: `init.sh` 脚本负责创建用户、设置密码、配置目录权限以及生成 `proftpd.conf` 文件。
*   **便捷服务管理**: `start.sh` 和 `stop.sh` 脚本用于控制 ProFTPD 服务。
*   **Docker 友好**: 设计为可以轻松打包并在 Docker 容器中运行。

## 先决条件

*   **Docker**: 必须安装在将运行 ProFTPD 服务器的远程开发机器上。
*   **VS Code**: 并安装 SFTP 插件 (例如 liximomo 开发的 "SFTP" 插件)。
*   **基础 Linux/Shell 知识**: 用于在远程机器上部署和运行脚本。

## 目录结构

```
proftpd/
├── bin/          # ProFTPD 二进制文件 (通常是 ProFTPD 安装包的一部分)
├── sbin/         # ProFTPD 守护进程 (proftpd)
├── etc/
│   └── proftpd.conf  # 主配置文件 (由 init.sh 生成)
├── include/      # ProFTPD 包含文件
├── lib/          # ProFTPD 库文件
├── libexec/      # ProFTPD 辅助程序
├── share/        # ProFTPD 共享数据
├── var/          # 运行时数据 (日志, PID 文件)
│   ├── proftpd.pid
│   ├── proftpd.system.log
│   └── proftpd.transfer.log
├── init.sh       # 初始化脚本 (创建用户, 设置密码, 配置)
├── start.sh      # 启动 ProFTPD 服务器的脚本
├── stop.sh       # 停止 ProFTPD 服务器的脚本
└── README.md     # 本中文版说明文档 (默认)
└── README_en.md  # 英文版说明文档
```
*(注意: `bin/`, `sbin/`, `include/`, `lib/`, `libexec/`, `share/` 目录通常是标准 ProFTPD 安装的一部分。如果你从一个最小化的包构建，请确保这些目录被正确填充，或者 ProFTPD 在 Docker 容器中已全局安装，并且这些脚本能够找到它。)*

## 安装与配置

**在远程开发机器上 (Docker 内部或直接部署):**

1.  **部署文件**:
    *   将整个项目目录 (包含 `init.sh`, `start.sh`, `stop.sh` 以及 ProFTPD 的安装子目录) 传输到你的远程机器。可以选择任意合适的位置，比如 `/home/Code/ftp_sync`、`/opt/ftp_sync` 等。

2.  **进入项目目录**:
    ```bash
    cd [你的项目目录路径]
    ```
    *(请将 `[你的项目目录路径]` 替换为实际的部署路径)*

3.  **运行初始化脚本**:
    
    🎯 **新特性**: 现在支持自定义 FTP 工作目录！
    
    **交互式配置**（推荐）：
    ```bash
    bash ./init.sh
    # 脚本会提示你输入或选择 FTP 工作目录
    # 默认为 /home/Code，也可以指定其他路径
    ```
    
    **命令行参数模式**：
    ```bash
    # 使用默认路径
    bash ./init.sh /home/Code
    
    # 或指定自定义路径
    bash ./init.sh /var/www/myproject
    ```
    
    *   此脚本将执行以下操作:
        *   提示选择或输入 FTP 工作目录路径
        *   创建 `ftpuser` 用户 (如果不存在)，其主目录为指定路径
        *   设置 `ftpuser` 的密码为 `ftp123`
        *   为指定目录以及 ProFTPD 安装目录设置合适的所有权和权限
        *   生成一个全新的 `etc/proftpd.conf` 配置文件，适应所选路径
        *   显示完整的 VS Code SFTP 配置示例
    
    *   请仔细检查 `init.sh` 的输出，确保没有错误。

4.  **启动 ProFTPD 服务器**:
    ```bash
    bash ./start.sh
    ```
    *   这将在后台启动 ProFTPD 守护进程。
    *   检查错误: `cat var/proftpd.system.log`
    *   验证服务是否正在运行: `ps aux | grep proftpd`

**在你的本地机器上 (VS Code):**

1.  **安装 SFTP 插件**: 如果尚未安装，请从 VS Code Marketplace 安装一个 SFTP 插件，例如 liximomo 开发的 "SFTP"。

2.  **配置 `sftp.json`**:
    *   在你的本地 VS Code 项目中，创建或修改 `.vscode/sftp.json` 文件:
    ```json
    {
        "name": "我的远程开发服务器",
        "host": "your_remote_machine_ip_or_hostname", // 替换为你的远程机器IP或主机名
        "protocol": "ftp", // 重要: 使用 'ftp', 而非 'sftp'
        "port": 8021,     // 必须与 proftpd.conf 中的 Port 一致
        "username": "ftpuser",
        "password": "ftp123",
        "remotePath": "/home/Code", // 服务器上的目标目录
        "uploadOnSave": true,
        "useTempFile": false,
        "openSsh": false,
        "passive": true, // 对于通过防火墙/NAT的FTP连接通常有帮助
        "watcher": {
            "files": "**/*", // 根据需要调整 glob 模式
            "autoUpload": true,
            "autoDelete": true
        },
        "ignore": [
            ".vscode",
            ".git",
            ".DS_Store",
            "**/node_modules/**"
        ]
    }
    ```
    *   **关键设置**:
        *   `host`: 你的远程机器的 IP 地址或主机名 (如果是通过端口转发的 Docker 主机，则填写 Docker 主机的 IP)。
        *   `protocol`: 必须是 `"ftp"`。
        *   `port`: 必须是 `8021` (由 `init.sh` 在 `proftpd.conf` 中定义)。
        *   `username`: `"ftpuser"`。
        *   `password`: `"ftp123"`。
        *   `remotePath`: `"/home/Code"`。
        *   `passive`: 通常建议设置为 `true`。

3.  **连接与同步**:
    *   使用你的 SFTP 插件的命令 (通常在 VS Code 命令面板中输入 "SFTP" 找到) 来连接、上传、下载或同步你的项目。

## 多服务器 SFTP 配置

### 方案一：使用 Profiles 配置（推荐）

这是最灵活且高效的多服务器配置方式：

```json
{
    "name": "默认服务器",
    "protocol": "ftp",
    "port": 8021,
    "username": "ftpuser",
    "password": "ftp123",
    "remotePath": "/home/Code",
    "uploadOnSave": true,
    "passive": true,
    "profiles": {
        "dev": {
            "name": "开发环境",
            "host": "dev-server.example.com",
            "remotePath": "/home/Code/dev",
            "uploadOnSave": true
        },
        "test": {
            "name": "测试环境",
            "host": "test-server.example.com",
            "remotePath": "/home/Code/test",
            "uploadOnSave": false
        },
        "prod": {
            "name": "生产环境",
            "host": "prod-server.example.com",
            "remotePath": "/home/Code/prod",
            "uploadOnSave": false
        }
    },
    "defaultProfile": "dev",
    "ignore": [
        ".vscode",
        ".git",
        ".DS_Store",
        "node_modules/**",
        "*.log"
    ]
}
```

**切换服务器**: 使用命令 `SFTP: Set Profile` 来快速切换不同的服务器环境。

### 方案二：多配置数组

适用于完全不同的项目或工作区：

```json
[
    {
        "name": "项目A - 生产环境",
        "context": "./project-a",
        "host": "server1.example.com",
        "protocol": "ftp",
        "port": 8021,
        "username": "ftpuser",
        "password": "ftp123",
        "remotePath": "/home/Code/project-a",
        "uploadOnSave": true,
        "passive": true
    },
    {
        "name": "项目B - 开发环境",
        "context": "./project-b",
        "host": "server2.example.com",
        "protocol": "ftp",
        "port": 8021,
        "username": "ftpuser",
        "password": "ftp123",
        "remotePath": "/home/Code/project-b",
        "uploadOnSave": true,
        "passive": true
    }
]
```

**重要说明**:
- `context`: 指定本地目录，让不同的项目文件夹使用不同的远程连接
- 每个配置的 `context` 必须不同
- `name` 在数组模式下是必需的

### 方案三：多配置文件管理

为不同环境创建独立的配置文件：

```bash
.vscode/
├── sftp.json          # 默认配置
├── sftp-dev.json      # 开发环境
├── sftp-test.json     # 测试环境
└── sftp-prod.json     # 生产环境
```

使用 `SFTP: Config` 命令时，可以选择加载不同的配置文件。

### 高级配置选项

```json
{
    "name": "高级配置示例",
    "host": "your-server.com",
    "protocol": "ftp",
    "port": 8021,
    "username": "ftpuser",
    "password": "ftp123",
    "remotePath": "/home/Code",
    "uploadOnSave": true,
    "downloadOnOpen": false,
    "passive": true,
    "ignore": [
        ".vscode",
        ".git/**",
        "*.log",
        "node_modules/**",
        "dist/**",
        "build/**"
    ],
    "watcher": {
        "files": "src/**/*.{js,ts,css,html}",
        "autoUpload": true,
        "autoDelete": false
    },
    "concurrency": 4,
    "connectTimeout": 30000,
    "keepalive": 30000
}
```

**配置说明**:
- `downloadOnOpen`: 打开文件时是否自动下载
- `watcher`: 文件监视器，可以监视特定文件变化
- `concurrency`: 并发传输数量
- `connectTimeout`: 连接超时时间（毫秒）
- `keepalive`: 连接保持时间（毫秒）

## 管理 ProFTPD 服务

在远程机器的项目目录下:

*   **启动服务**:
    ```bash
    bash ./start.sh
    ```
*   **停止服务**:
    ```bash
    bash ./stop.sh
    ```
*   **查看系统日志**:
    ```bash
    tail -f var/proftpd.system.log
    ```
*   **查看传输日志**:
    ```bash
    tail -f var/proftpd.transfer.log
    ```

## 故障排除

*   **登录不正确 (530 Login incorrect)**:
    *   仔细检查 `sftp.json` 中的 `username` 和 `password` 是否与 `ftpuser` 和 `ftp123` 匹配。
    *   确保 `init.sh` 已成功运行并设置了密码。
    *   查看 `var/proftpd.system.log` 获取详细错误信息。`proftpd.conf` 中应包含 `RequireValidShell off` 以允许 shell 为 `/sbin/nologin` 的用户登录。
*   **连接被拒/超时 (Connection Refused/Timeout)**:
    *   验证 ProFTPD 是否正在远程服务器上运行: `ps aux | grep proftpd`。
    *   确保 `sftp.json` 中的 `port` (8021) 与 `etc/proftpd.conf` 中的 `Port` 一致。
    *   检查远程机器或任何中间网络设备上的防火墙规则。如果在 Docker 中运行，确保端口 (例如 8021 和被动模式端口 8000-8999) 已正确地从容器映射到主机。
*   **权限被拒 (文件操作时)**:
    *   确保 `init.sh` 已成功完成。它会将 `/home/Code` 和 `proftpd` 目录的所有权递归地设置为 `ftpuser`。
    *   验证 `ftpuser` 用户确实拥有远程服务器上 `/home/Code` 目录内目标文件/目录的所有权 (`ls -la /home/Code`)。
*   **被动模式问题 (Passive Mode Issues)**:
    *   如果在连接后上传/下载或目录列表卡住，则可能是被动模式问题。确保 `proftpd.conf` 中定义了 `PassivePorts 8000 8999`，并且此端口范围也已在防火墙上打开，并在使用 Docker 时进行了映射。
*   **"DefaultRoot 问题" / 文件上传到错误目录**:
    *   此设置特意避免依赖 ProFTPD 的 `DefaultRoot` 来限制用户根目录 (chroot)，因为它可能不稳定，尤其对于 `root` 用户。取而代之的是，`ftpuser` 会登录到其实际主目录 (`/home/Code`)，然后由 SFTP 客户端的 `remotePath: "/home/Code"` 来定位到正确的目录。如果从 FTP 客户端的角度看，文件仍然上传到 `/`，并且 `pwd` 命令显示 `/`，但 `ls` 命令列出的是 `/home/Code` 的内容，这是此配置的预期行为。关键在于，你的 SFTP 插件使用 `remotePath: "/home/Code"` 时，仍应能正确同步到该物理路径。

## 安全注意事项

*   **密码**: 默认密码 `ftp123` 是不安全的。对于任何生产或敏感环境，请在 `init.sh` (修改 `FTP_PASS` 变量) 中更改它，并相应更新你的 `sftp.json` 文件。
*   **防火墙**: 如果可能，将对端口 8021 和被动端口范围 (8000-8999) 的访问限制在受信任的 IP 地址。
*   **TLS/SSL**: 此配置不包含通过 TLS/SSL (FTPS) 的 FTP 来加密连接。为增强安全性，请考虑配置 ProFTPD 使用 TLS。
*   **权限**: `init.sh` 脚本授予 `ftpuser` 对 `/home/Code` 的广泛控制权。请审查这些权限是否符合你的安全模型。

## 📋 SFTP配置参数完整说明

### 核心配置项详解

| 配置项 | 类型 | 说明 | 示例值 |
|-------|------|------|--------|
| `name` | String | 配置名称，用于区分多个配置 | "开发环境" |
| `host` | String | 远程服务器地址，可以是IP或域名 | "192.168.1.100" |
| `protocol` | String | 传输协议，支持"ftp"或"sftp" | "ftp" |
| `port` | Number | 服务器端口号，FTP默认21，SFTP默认22 | 8021 |
| `username` | String | 登录用户名 | "ftpuser" |
| `password` | String | 登录密码 | "ftp123" |
| `remotePath` | String | 远程服务器上的目标路径 | "/home/Code" |
| `uploadOnSave` | Boolean | 保存文件时是否自动上传 | true |
| `syncMode` | String | 同步模式，"full"(完整同步)或"update"(仅更新) | "update" |

### 高级配置项详解

| 配置项 | 类型 | 说明 | 默认值 |
|-------|------|------|--------|
| `passive` | Boolean | 是否使用被动模式，解决某些防火墙环境下的连接问题 | true |
| `debug` | Boolean | 是否在输出窗口显示调试信息 | false |
| `retryOnError` | Boolean | 发生错误时是否尝试重新连接 | false |
| `retryCount` | Number | 重试次数上限 | 2 |
| `retryDelay` | Number | 两次重试之间的等待时间(毫秒) | 10000 |
| `ignore` | Array | 需要忽略的文件或文件夹，支持glob模式 | [] |
| `context` | String | 仅在指定文件夹下显示SFTP选项 | "./" |
| `connectTimeout` | Number | 连接超时时间(毫秒) | 10000 |
| `privateKeyPath` | String | SSH私钥路径，适用于SFTP协议 | - |
| `agent` | String | SSH代理路径，适用于SFTP协议 | - |
| `watcher` | Object | 文件变更监视器配置 | {} |

## 🔧 常见问题解决方案

### 连接失败问题

#### 1. 端口问题
**症状**: 连接超时或连接被拒
**解决方案**: 
- 确认服务器端口是否正确，FTP默认为21，SFTP默认为22
- 检查防火墙是否开放相应端口
- 使用 `netstat -anpt | grep 8021` 验证端口是否监听

#### 2. 防火墙问题
**症状**: 连接建立后数据传输失败
**解决方案**: 
```json
{
    "passive": true,
    "connectTimeout": 30000
}
```

#### 3. 认证失败
**症状**: 530 Login incorrect 错误
**解决方案**: 
- 检查用户名和密码是否正确
- 确认用户是否存在: `id ftpuser`
- 查看系统日志: `tail -f var/proftpd.system.log`

#### 4. 权限问题
**症状**: 无法上传或创建文件
**解决方案**: 
- 确认远程用户是否有读写权限
- 检查目录所有权: `ls -la /home/Code`
- 重新运行: `bash ./init.sh`

### 上传失败问题

#### 1. 文件权限
**解决方案**: 
```bash
# 检查远程目录权限
ls -la /home/Code
# 修复权限
chown -R ftpuser:ftpuser /home/Code
chmod -R 755 /home/Code
```

#### 2. 网络问题
**配置网络重试参数**: 
```json
{
    "retryOnError": true,
    "retryCount": 3,
    "retryDelay": 5000,
    "connectTimeout": 30000
}
```

#### 3. 路径问题
**解决方案**: 
- 确认 `remotePath` 是否正确
- 验证路径存在: `ls -la /home/Code`
- 使用绝对路径而非相对路径

## 🎯 高效使用技巧

### 命令面板操作

通过命令面板(`Ctrl+Shift+P` 或 `Cmd+Shift+P`)可以执行以下SFTP操作：

- **`SFTP: Config`** - 创建/编辑配置文件
- **`SFTP: Upload`** - 上传当前文件/文件夹
- **`SFTP: Download`** - 下载远程文件/文件夹
- **`SFTP: Sync Local -> Remote`** - 将本地同步到远程
- **`SFTP: Sync Remote -> Local`** - 将远程同步到本地
- **`SFTP: List`** - 列出远程目录内容
- **`SFTP: Cancel`** - 取消当前传输操作
- **`SFTP: Set Profile`** - 切换配置文件

### 性能优化技巧

#### 1. 文件忽略优化
```json
{
    "ignore": [
        ".git/**",
        "node_modules/**",
        "*.log",
        ".DS_Store",
        "dist/**",
        "build/**",
        "coverage/**",
        "*.tmp",
        "*.cache"
    ]
}
```

#### 2. 选择性同步
```json
{
    "watcher": {
        "files": "src/**/*.{js,ts,vue,css,html}",
        "autoUpload": true,
        "autoDelete": false
    }
}
```

#### 3. 并发传输优化
```json
{
    "concurrency": 4,
    "connectTimeout": 30000,
    "keepalive": 30000
}
```

### 环境切换最佳实践

#### 开发环境配置
```json
{
    "name": "开发环境",
    "uploadOnSave": true,
    "syncMode": "update",
    "debug": false,
    "retryOnError": true
}
```

#### 生产环境配置
```json
{
    "name": "生产环境",
    "uploadOnSave": false,
    "syncMode": "full",
    "debug": true,
    "retryOnError": true,
    "retryCount": 5
}
```

## 🔒 安全配置建议

### 1. 密码安全
- 不要将包含密码的配置文件提交到版本控制系统
- 考虑使用SSH密钥认证替代密码认证
- 定期更新密码

### 2. 访问控制
```bash
# 在 .gitignore 中添加
.vscode/sftp.json
.vscode/sftp-*.json
```

### 3. 网络安全
- 限制远程文件夹访问权限
- 使用VPN或专网访问生产环境
- 配置防火墙规则限制IP访问

### 4. 审计日志
```bash
# 定期检查传输日志
tail -f var/proftpd.transfer.log

# 监控系统日志
tail -f var/proftpd.system.log
```

## 🚀 高级配置示例

### 多项目工作区配置
```json
{
    "configurations": [
        {
            "name": "前端项目",
            "context": "./frontend",
            "host": "frontend-server.com",
            "remotePath": "/var/www/frontend",
            "watcher": {
                "files": "src/**/*.{js,vue,css}"
            }
        },
        {
            "name": "后端项目",
            "context": "./backend", 
            "host": "backend-server.com",
            "remotePath": "/home/app/backend",
            "watcher": {
                "files": "**/*.{py,js,json}"
            }
        }
    ]
}
```

### 条件上传配置
```json
{
    "uploadOnSave": true,
    "downloadOnOpen": false,
    "watcher": {
        "files": "**/*",
        "autoUpload": true,
        "autoDelete": false,
        "patterns": {
            "**/*.log": false,
            "**/*.tmp": false,
            "src/**": true
        }
    }
}
```

---

🎉 **恭喜！** 你已完成 ProFTPD 服务器配置和 VS Code 同步的完整设置。

本文档为你的 ProFTPD 服务器配置和 VS Code 同步提供了全面的中文指南。如有问题，请查看日志文件或重新执行初始化步骤。 