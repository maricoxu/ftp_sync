#!/bin/sh

CURPATH=$(cd $(dirname $0); pwd)
CONFIGFILE="$CURPATH/etc/proftpd.conf"
PROFTPD_BIN="$CURPATH/sbin/proftpd"
PIDFILE_EXPECTED_PATH="$CURPATH/var/proftpd.pid" # Used for messaging

# Check if ProFTPD binary exists
if [ ! -x "$PROFTPD_BIN" ]; then
    echo "Error: ProFTPD binary not found or not executable at $PROFTPD_BIN" >&2
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIGFILE" ]; then
    echo "Error: ProFTPD config file not found at $CONFIGFILE" >&2
    exit 1
fi

# Check if already running by looking for a PID file and an active process
if [ -f "$PIDFILE_EXPECTED_PATH" ]; then
    OLD_PID=$(cat "$PIDFILE_EXPECTED_PATH")
    if [ -n "$OLD_PID" ] && ps -p "$OLD_PID" > /dev/null; then
        echo "ProFTPD appears to be already running with PID $OLD_PID. If not, remove $PIDFILE_EXPECTED_PATH." >&2
        exit 1
    else
        echo "Warning: Stale PID file found ($PIDFILE_EXPECTED_PATH). Removing it." >&2
        rm -f "$PIDFILE_EXPECTED_PATH"
    fi
fi

echo "Starting ProFTPD..."
# The -n option runs ProFTPD in non-daemon (foreground) mode for the main process,
# but it will still fork children. ProFTPD itself handles daemonizing if not -n.
# ProFTPD will create the PID file as specified by the PidFile directive in its config.
"$PROFTPD_BIN" -c "$CONFIGFILE"

# Check exit status
if [ $? -eq 0 ]; then
    echo "ProFTPD start command executed."
    echo "Please check ProFTPD logs and 'ps aux | grep proftpd' to confirm it is running."
    echo "Ensure 'PidFile $PIDFILE_EXPECTED_PATH' (or similar) is correctly set in $CONFIGFILE for stop.sh to work reliably."
else
    echo "Failed to execute ProFTPD start command. Check for errors above or in ProFTPD logs." >&2
    exit 1
fi

exit 0
