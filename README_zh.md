# ProFTPD 服务器：用于 VS Code SFTP 同步

本项目提供了一个预配置的 ProFTPD 服务器设置，旨在 Docker 容器内部运行。它通过 SFTP 协议，简化了本地 VS Code 工作区与远程开发机器之间的文件同步。

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
└── README.md     # 英文版说明文档
└── README_zh.md  # 本中文版说明文档
```
*(注意: `bin/`, `sbin/`, `include/`, `lib/`, `libexec/`, `share/` 目录通常是标准 ProFTPD 安装的一部分。如果你从一个最小化的包构建，请确保这些目录被正确填充，或者 ProFTPD 在 Docker 容器中已全局安装，并且这些脚本能够找到它。)*

## 安装与配置

**在远程开发机器上 (Docker 内部或直接部署):**

1.  **部署文件**:
    *   将整个 `proftpd` 目录 (包含 `init.sh`, `start.sh`, `stop.sh` 以及 ProFTPD 的安装子目录) 传输到你的远程机器。在 Docker 环境中，一个常见的位置可能是 `/home/Code/proftpd_server_files` 或类似路径。我们假设它被放置在 `/opt/proftpd_setup`。

2.  **进入目录**:
    ```bash
    cd /opt/proftpd_setup 
    ```
    *(请根据你的实际部署路径调整)*

3.  **运行初始化脚本**:
    *   此脚本将执行以下操作:
        *   创建 `ftpuser` 用户 (如果不存在)，其主目录为 `/home/Code`。
        *   设置 `ftpuser` 的密码为 `ftp123`。
        *   为 `/home/Code` 目录以及 ProFTPD 安装目录本身设置合适的所有权和权限。
        *   生成一个全新的 `etc/proftpd.conf` 配置文件，以适应此设置。
    ```bash
    bash ./init.sh
    ```
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

## 管理 ProFTPD 服务

在远程机器的 `proftpd` 目录下 (例如 `/opt/proftpd_setup`):

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

本 `README_zh.md` 文件为你的 ProFTPD 服务器配置和 VS Code 同步提供了全面的中文指南。 