# ProFTPD Server for VS Code SFTP Synchronization

This project provides a pre-configured ProFTPD server setup, intended to be run inside a Docker container. It facilitates file synchronization between a local VS Code workspace and a remote development machine via the SFTP protocol.

The server is configured to use a dedicated FTP user (`ftpuser`) whose home directory is set to `/home/Code` on the remote machine. This `/home/Code` directory is also intended to be the target for your VS Code SFTP plugin's `remotePath`.

## Features

*   **Dedicated FTP User**: Uses a non-root user (`ftpuser`) for FTP access.
*   **Targeted Sync Directory**: Configured for syncing to `/home/Code`.
*   **Automated Setup**: `init.sh` script handles user creation, password setting, directory permissions, and `proftpd.conf` generation.
*   **Easy Service Management**: `start.sh` and `stop.sh` scripts for controlling the ProFTPD service.
*   **Docker-Friendly**: Designed to be easily packaged and run within a Docker container.

## Prerequisites

*   **Docker**: Must be installed on the remote development machine where the ProFTPD server will run.
*   **VS Code**: With an SFTP plugin (e.g., "SFTP" by liximomo).
*   **Basic Linux/Shell Knowledge**: For deploying and running scripts on the remote machine.

## Directory Structure

```
proftpd/
├── bin/          # ProFTPD binaries (usually part of a ProFTPD installation package)
├── sbin/         # ProFTPD daemon (proftpd)
├── etc/
│   └── proftpd.conf  # Main configuration file (generated by init.sh)
├── include/      # ProFTPD include files
├── lib/          # ProFTPD libraries
├── libexec/      # ProFTPD helper programs
├── share/        # ProFTPD shared data
├── var/          # Runtime data (logs, PID file)
│   ├── proftpd.pid
│   ├── proftpd.system.log
│   └── proftpd.transfer.log
├── init.sh       # Initialization script (creates user, sets password, configures)
├── start.sh      # Script to start the ProFTPD server
├── stop.sh       # Script to stop the ProFTPD server
└── README.md     # This file
```
*(Note: The `bin/`, `sbin/`, `include/`, `lib/`, `libexec/`, `share/` directories are typically part of a standard ProFTPD installation. If you are building from a minimal package, ensure these are correctly populated or ProFTPD is installed system-wide in the Docker container and these scripts can find it.)*

## Setup and Configuration

**On the Remote Development Machine (inside Docker or directly):**

1.  **Deploy Files**:
    *   Transfer the entire `proftpd` directory (containing `init.sh`, `start.sh`, `stop.sh`, and the ProFTPD installation subdirectories) to your remote machine. A common location within a Docker setup might be `/home/Code/proftpd_server_files` or similar. Let's assume it's placed at `/opt/proftpd_setup`.

2.  **Navigate to the Directory**:
    ```bash
    cd /opt/proftpd_setup 
    ```
    *(Adjust path as per your deployment)*

3.  **Run Initialization Script**:
    *   This script will:
        *   Create the `ftpuser` user (if it doesn't exist) with home directory `/home/Code`.
        *   Set the password for `ftpuser` to `ftp123`.
        *   Set appropriate ownership and permissions for `/home/Code` and the ProFTPD installation directory itself.
        *   Generate a fresh `etc/proftpd.conf` file tailored for this setup.
    ```bash
    bash ./init.sh
    ```
    *   Carefully review the output of `init.sh` for any errors.

4.  **Start ProFTPD Server**:
    ```bash
    bash ./start.sh
    ```
    *   This will start the ProFTPD daemon in the background.
    *   Check for errors: `cat var/proftpd.system.log`
    *   Verify it's running: `ps aux | grep proftpd`

**On Your Local Machine (VS Code):**

1.  **Install an SFTP Plugin**: If you haven't already, install an SFTP plugin like "SFTP" by liximomo from the VS Code Marketplace.

2.  **Configure `sftp.json`**:
    *   In your local VS Code project, create or modify the `.vscode/sftp.json` file:
    ```json
    {
        "name": "My Remote Dev Server",
        "host": "your_remote_machine_ip_or_hostname",
        "protocol": "ftp", // Important: Use 'ftp', not 'sftp'
        "port": 8021,     // Must match the Port in proftpd.conf
        "username": "ftpuser",
        "password": "ftp123",
        "remotePath": "/home/Code", // Target directory on the server
        "uploadOnSave": true,
        "useTempFile": false,
        "openSsh": false,
        "passive": true, // Often helpful for FTP through firewalls/NAT
        "watcher": {
            "files": "**/*", // Adjust glob pattern as needed
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
    *   **Key settings**:
        *   `host`: The IP address or hostname of your remote machine (or the Docker host if port forwarding is set up).
        *   `protocol`: Must be `"ftp"`.
        *   `port`: Must be `8021` (as defined in `proftpd.conf` by `init.sh`).
        *   `username`: `"ftpuser"`.
        *   `password`: `"ftp123"`.
        *   `remotePath`: `"home/Code"`.
        *   `passive`: Set to `true` is generally recommended.

3.  **Connect and Synchronize**:
    *   Use your SFTP plugin's commands (usually found in the VS Code command palette by typing "SFTP") to connect, upload, download, or synchronize your project.

## Managing the ProFTPD Service

From the `proftpd` directory on the remote machine (e.g., `/opt/proftpd_setup`):

*   **Start Server**:
    ```bash
    bash ./start.sh
    ```
*   **Stop Server**:
    ```bash
    bash ./stop.sh
    ```
*   **View System Log**:
    ```bash
    tail -f var/proftpd.system.log
    ```
*   **View Transfer Log**:
    ```bash
    tail -f var/proftpd.transfer.log
    ```

## Troubleshooting

*   **Login Incorrect (530)**:
    *   Double-check the `username` and `password` in `sftp.json` match `ftpuser` and `ftp123`.
    *   Ensure `init.sh` ran successfully and set the password.
    *   Check `var/proftpd.system.log` for detailed error messages. `RequireValidShell off` should be in `proftpd.conf` to allow login for users with `/sbin/nologin`.
*   **Connection Refused/Timeout**:
    *   Verify ProFTPD is running on the remote server: `ps aux | grep proftpd`.
    *   Ensure the `port` in `sftp.json` (8021) matches the `Port` in `etc/proftpd.conf`.
    *   Check firewall rules on the remote machine or any intermediate network devices. If running in Docker, ensure the port (e.g., 8021 and passive ports 8000-8999) are correctly mapped from the container to the host.
*   **Permission Denied (on file operations)**:
    *   Ensure `init.sh` completed successfully. It sets ownership of `/home/Code` and the `proftpd` directory recursively to `ftpuser`.
    *   Verify that the `ftpuser` indeed owns the target files/directories within `/home/Code` on the remote server (`ls -la /home/Code`).
*   **Passive Mode Issues**:
    *   If uploads/downloads or directory listings hang after connection, it might be a passive mode issue. Ensure `PassivePorts 8000 8999` are defined in `proftpd.conf` and that this port range is also open on your firewall and mapped if using Docker.
*   **"DefaultRoot problem" / Files go to wrong directory**:
    *   This setup deliberately avoids relying on ProFTPD's `DefaultRoot` to chroot the user, as it can be inconsistent, especially with the `root` user. Instead, `ftpuser` logs into its actual home directory (`/home/Code`), and the SFTP client's `remotePath: "/home/Code"` handles targeting the correct directory. If files are still going to `/` from the FTP client's perspective, and `pwd` shows `/`, but `ls` lists the contents of `/home/Code`, this is the expected behavior of this configuration. The key is that your SFTP plugin, using `remotePath: "/home/Code"`, should still sync correctly to that physical path.

## Security Considerations

*   **Password**: The default password `ftp123` is insecure. Change it in `init.sh` (`FTP_PASS` variable) and update your `sftp.json` accordingly for any production or sensitive environment.
*   **Firewall**: Restrict access to port 8021 and the passive port range (8000-8999) to trusted IP addresses if possible.
*   **TLS/SSL**: This configuration does not include FTP over TLS/SSL (FTPS) for encrypted connections. For enhanced security, consider configuring ProFTPD with TLS.
*   **Permissions**: The `init.sh` script grants `ftpuser` broad control over `/home/Code`. Review if these permissions are appropriate for your security model.

This `README.md` provides a comprehensive guide to get your ProFTPD server up and running for VS Code synchronization. 