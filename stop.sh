#!/bin/sh

CURPATH=$(cd $(dirname $0); pwd)
PIDFILE="$CURPATH/var/proftpd.pid"

echo "Attempting to stop ProFTPD..."

if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if [ -n "$PID" ] && ps -p "$PID" > /dev/null; then
        echo "Stopping ProFTPD (PID: $PID) using PID file..."
        kill "$PID"
        # Wait for a moment and check if process is gone
        sleep 2 
        if ps -p "$PID" > /dev/null ; then
            echo "ProFTPD (PID: $PID) did not stop gracefully, sending SIGKILL..."
            kill -9 "$PID"
        fi
        rm -f "$PIDFILE"
        echo "ProFTPD stopped (or at least signaled to stop)."
    else
        echo "PID file found ($PIDFILE), but no such process (PID: $PID) is running or PID is empty. Cleaning up PID file."
        rm -f "$PIDFILE"
    fi
else
    echo "ProFTPD PID file ($PIDFILE) not found."
    echo "Attempting to find and stop ProFTPD by process name (this might be less precise)..."
    # Fallback: find proftpd process by name. This is less reliable.
    # The pattern looks for the main ProFTPD process.
    PIDS=$(ps aux | grep 'proftpd: (accepting connections)' | grep -v grep | awk '{print $2}')
    if [ -n "$PIDS" ]; then
        echo "Found ProFTPD process(es) by name (PIDS: $PIDS). Sending SIGTERM..."
        kill $PIDS
        sleep 2
        PIDS_AFTER=$(ps aux | grep 'proftpd: (accepting connections)' | grep -v grep | awk '{print $2}')
        if [ -n "$PIDS_AFTER" ]; then
             echo "Some ProFTPD processes may not have stopped gracefully. Sending SIGKILL to PIDS: $PIDS_AFTER ..."
             kill -9 $PIDS_AFTER
        fi
        echo "ProFTPD stop attempt by name finished."
    else
        echo "No ProFTPD process found running (searched by name)."
    fi
fi

exit 0 