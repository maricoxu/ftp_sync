#!/bin/sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CURPATH=$(cd $(dirname $0); pwd)
FTP_USER="ftpuser"
FTP_PASS="ftp123"
DEFAULT_FTP_HOME="/home/Code"  # 默认路径

# 函数：验证路径格式
validate_path() {
    local path="$1"
    # 检查是否为绝对路径
    if [[ ! "$path" =~ ^/ ]]; then
        echo -e "${RED}❌ 错误：路径必须是绝对路径（以 / 开头）${NC}"
        return 1
    fi
    # 检查是否为根目录
    if [ "$path" = "/" ]; then
        echo -e "${RED}❌ 错误：不能使用根目录作为FTP目录${NC}"
        return 1
    fi
    # 检查路径中是否包含特殊字符
    if [[ "$path" =~ [[:space:]] ]]; then
        echo -e "${YELLOW}⚠️ 警告：路径包含空格，可能在某些环境下出现问题${NC}"
    fi
    return 0
}

# 获取FTP主目录配置
echo -e "${BLUE}🎯 === ProFTPD 服务器初始化配置 === ${NC}"
echo ""

if [ $# -eq 1 ]; then
    # 命令行参数模式
    FTP_HOME="$1"
    echo -e "${CYAN}📝 使用命令行参数指定的路径: ${YELLOW}$FTP_HOME${NC}"
else
    # 交互模式
    echo -e "${CYAN}📂 请设置 FTP 服务器的工作目录（这将是VS Code同步的目标路径）${NC}"
    echo -e "${CYAN}   默认路径: ${YELLOW}$DEFAULT_FTP_HOME${NC}"
    echo ""
    echo -e "${CYAN}选项：${NC}"
    echo -e "${CYAN}  1. 直接按 Enter 使用默认路径${NC}"
    echo -e "${CYAN}  2. 输入自定义的绝对路径${NC}"
    echo ""
    echo -n -e "${YELLOW}请输入FTP工作目录路径 [默认: $DEFAULT_FTP_HOME]: ${NC}"
    read user_input
    
    if [ -z "$user_input" ]; then
        FTP_HOME="$DEFAULT_FTP_HOME"
        echo -e "${GREEN}✓ 使用默认路径: $FTP_HOME${NC}"
    else
        FTP_HOME="$user_input"
        echo -e "${CYAN}📝 用户指定路径: $FTP_HOME${NC}"
    fi
fi

# 验证路径
if ! validate_path "$FTP_HOME"; then
    echo -e "${RED}❌ 初始化失败：路径格式不正确${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}=== 开始配置 FTP 用户 '$FTP_USER' 和目录 '$FTP_HOME' ===${NC}"

# Create FTP_HOME if it doesn't exist
mkdir -p "$FTP_HOME"
echo -e "${GREEN}✓ 确保目录 $FTP_HOME 存在${NC}"

# Create ftpuser if it doesn't exist
if ! id -u "$FTP_USER" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  用户 '$FTP_USER' 不存在，正在创建...${NC}"
    useradd "$FTP_USER" -d "$FTP_HOME" -s /sbin/nologin
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 用户 '$FTP_USER' 创建成功${NC}"
    else
        echo -e "${RED}✗ 创建用户 '$FTP_USER' 失败，退出程序${NC}" >&2
        exit 1
    fi
else
    echo -e "${CYAN}ℹ️  用户 '$FTP_USER' 已存在${NC}"
    # Ensure home directory and shell are correctly set if user exists
    usermod -d "$FTP_HOME" -s /sbin/nologin "$FTP_USER"
    echo -e "${GREEN}✓ 确保用户 '$FTP_USER' 的主目录为 '$FTP_HOME'，shell 为 /sbin/nologin${NC}"
fi

# Set password for ftpuser
echo -e "${YELLOW}🔐 正在为用户 '$FTP_USER' 设置密码...${NC}"
echo "$FTP_USER:$FTP_PASS" | chpasswd
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 用户 '$FTP_USER' 密码设置成功${NC}"
else
    echo -e "${RED}⚠️  设置用户 '$FTP_USER' 密码失败，请检查 chpasswd 命令${NC}" >&2
    # Continue, as proftpd might work if password was set manually or previously
fi

# Set ownership and permissions for FTP_HOME
chown "$FTP_USER:$FTP_USER" "$FTP_HOME"
chmod 755 "$FTP_HOME" # Owner rwx, group rx, others rx
echo -e "${GREEN}✓ 设置 $FTP_HOME 的所有者为 $FTP_USER:$FTP_USER，权限为 755${NC}"

# Recursively set ownership and permissions for contents of $FTP_HOME
echo -e "${YELLOW}📁 正在递归设置 $FTP_HOME 内容的所有权和权限...${NC}"
# Ensure ftpuser owns all files and subdirectories within FTP_HOME
chown -R "$FTP_USER:$FTP_USER" "$FTP_HOME/"
# Set permissions: ftpuser gets rwx for directories, rw for files.
# For directories: ftpuser rwx, group rx, others rx (755 equivalent for user, restricted for others)
# For files: ftpuser rw-, group r--, others r-- (644 equivalent for user, restricted for others)
# Using u+rwX is a good general approach for the owner.
chmod -R u+rwX "$FTP_HOME/"
# If specific group/other permissions are needed and are different from what u+rwX implies
# for group/other (which it doesn't directly set beyond umask defaults), add them separately.
# For example, to ensure group can read and traverse, and others can traverse (for directories):
# find "$FTP_HOME" -type d -exec chmod g+rx,o+x {} \;
# find "$FTP_HOME" -type f -exec chmod g+r,o+r {} \;
echo -e "${GREEN}✓ 完成 $FTP_HOME 的递归权限设置${NC}"

# Ensure the var directory exists for logs and PID file, owned by ftpuser
mkdir -p "$CURPATH/var"
chown -R "$FTP_USER:$FTP_USER" "$CURPATH/var"
echo -e "${GREEN}✓ 确保 $CURPATH/var 存在并属于用户 $FTP_USER${NC}"

# Also ensure the entire proftpd application directory ($CURPATH) is accessible by ftpuser
# This is important if the SFTP client tries to read/write files within this directory structure,
# e.g., if the local workspace maps to a structure including these scripts/configs.
chown -R "$FTP_USER:$FTP_USER" "$CURPATH"
chmod -R u+rwX,go+rX-w "$CURPATH" # ftpuser gets rwx, group/other get rx (no write for others)
echo -e "${GREEN}✓ 设置项目目录 $CURPATH 的所有者为 $FTP_USER 并调整权限${NC}"

echo -e "\n${BLUE}=== 为用户 '$FTP_USER' 配置 ProFTPD ===${NC}"
PROCONF_TARGET="$CURPATH/etc/proftpd.conf"

# Overwrite proftpd.conf with a new configuration tailored for ftpuser
# This avoids complex sed operations on a potentially unknown base file.
echo -e "${YELLOW}📝 正在生成新的配置文件 $PROCONF_TARGET...${NC}"

cat > "$PROCONF_TARGET" << EOF
# proftpd.conf generated by init.sh for user $FTP_USER

ServerName                      "ProFTPD Server for $FTP_USER"
ServerType                      standalone
DefaultServer                   on

Port                            8021
PassivePorts                    8000 8999
UseIPv6                         off
Umask                           022
MaxInstances                    30

# Run ProFTPD processes as $FTP_USER
User                            $FTP_USER
Group                           $FTP_USER

# DefaultRoot is intentionally commented out or omitted.
# Rely on SFTP client's remotePath setting to target $FTP_HOME.
# If DefaultRoot were to be used and chroot worked, it would typically be:
# DefaultRoot                   $FTP_HOME
# or for chrooting to user's home dir (which is $FTP_HOME for $FTP_USER):
# DefaultRoot                   ~

AllowOverwrite                  on
RequireValidShell               off # Crucial for users with /sbin/nologin

# Disable root login via FTP
# RootLogin                       on

# Disable .ftpaccess files (optional, for simplicity)
# AllowOverride                 off

# Authentication: Use system users, not AuthUserFile/AuthGroupFile
# AuthUserFile                    $CURPATH/var/ftpd.passwd
# AuthGroupFile                   $CURPATH/var/ftpd.group

# Disable Anonymous login
# <Anonymous ~>
#   User                        $FTP_USER
#   Group                       $FTP_USER
#   UserAlias                   anonymous ftp
#   MaxClients                  10
#   DisplayLogin                welcome.msg
#   DisplayChdir                .message
#   <Limit WRITE>
#     DenyAll
#   </Limit>
# </Anonymous>

# Paths for PID file and logs - ensure $CURPATH/var is writable by $FTP_USER
PidFile                         $CURPATH/var/proftpd.pid
SystemLog                       $CURPATH/var/proftpd.system.log
TransferLog                     $CURPATH/var/proftpd.transfer.log

# Optional: Add DelayTable if mod_delay is active, to prevent brute-force attacks
# DelayTable                    $CURPATH/var/proftpd.delay

# Optional: Security settings
# Deny SUID/SGID remote bits from being set
# <Limit SITE_CHMOD>
#   DenyAll
# </Limit>

EOF

echo -e "${GREEN}✓ 配置文件 $PROCONF_TARGET 生成成功${NC}"
echo -e "${CYAN}📋 配置概要:${NC}"
echo -e "  ${CYAN}用户: $FTP_USER${NC}"
echo -e "  ${CYAN}用户组: $FTP_USER${NC}"
echo -e "  ${CYAN}DefaultRoot: (已省略/注释)${NC}"
echo -e "  ${CYAN}RequireValidShell: 关闭${NC}"
echo -e "  ${CYAN}RootLogin: (已注释/禁用)${NC}"
echo -e "  ${CYAN}匿名登录: (已注释/禁用)${NC}"
echo -e "  ${CYAN}AuthUserFile/AuthGroupFile: (已注释/禁用)${NC}"

echo -e "\n${GREEN}🎉 =========================${NC}"
echo -e "${GREEN}🎉 初始化设置完成！${NC}"
echo -e "${GREEN}🎉 =========================${NC}"
echo ""
echo -e "${PURPLE}📋 配置概要：${NC}"
echo -e "${CYAN}   • FTP用户: ${YELLOW}$FTP_USER${NC}"
echo -e "${CYAN}   • 用户密码: ${YELLOW}$FTP_PASS${NC}"
echo -e "${CYAN}   • 工作目录: ${YELLOW}$FTP_HOME${NC}"
echo -e "${CYAN}   • 服务端口: ${YELLOW}8021${NC}"
echo ""
echo -e "${PURPLE}🚀 下一步操作：${NC}"
echo -e "${CYAN}1.${NC} 运行 ${YELLOW}bash ./start.sh${NC} 启动 ProFTPD 服务"
echo -e "${CYAN}2.${NC} 在 VS Code 中创建 ${YELLOW}.vscode/sftp.json${NC} 配置："
echo ""
echo -e "${PURPLE}📝 VS Code SFTP 配置示例:${NC}"
echo -e "${YELLOW}{"
echo -e "    \"name\": \"我的开发服务器\","
echo -e "    \"host\": \"your-server-ip\","
echo -e "    \"protocol\": \"ftp\","
echo -e "    \"port\": 8021,"
echo -e "    \"username\": \"$FTP_USER\","
echo -e "    \"password\": \"$FTP_PASS\","
echo -e "    \"remotePath\": \"$FTP_HOME\","
echo -e "    \"uploadOnSave\": true,"
echo -e "    \"passive\": true"
echo -e "}${NC}"
echo ""
echo -e "${CYAN}3.${NC} 使用 VS Code 命令面板 ${YELLOW}Ctrl+Shift+P${NC} → ${YELLOW}SFTP: Upload${NC}"
echo ""
echo -e "${RED}⚠️  重要提示:${NC}"
echo -e "${RED}   • 在配置中将 ${YELLOW}your-server-ip${RED} 替换为实际的服务器IP地址${NC}"
echo -e "${RED}   • 如果启动失败，请检查 ${YELLOW}$CURPATH/var/proftpd.system.log${NC}"
echo -e "${GREEN}   • 更多配置选项请参考 ${YELLOW}README.md${GREEN} 和 ${YELLOW}QUICKSTART.md${NC}"
echo ""
