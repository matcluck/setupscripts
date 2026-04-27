#!/usr/bin/env bash
# fix-inotify-watches.sh
#
# Bump kernel inotify limits so editors (Sublime Text, VS Code, JetBrains, nvim
# with file-watcher plugins) can watch every file in a large project without
# silently dropping events.
#
# Default Debian/Ubuntu values are tiny:
#   max_user_watches    65536    -> too few for monorepos / node_modules
#   max_user_instances    128    -> hits cap once a few editors are open
#   max_queued_events   16384    -> events get dropped under bursty I/O
#
# This script writes /etc/sysctl.d/90-inotify.conf for persistence across
# reboots AND applies the new values live by writing to /proc, so you don't
# have to log out or restart anything.
#
# Idempotent: re-running just refreshes the file and the live values.

set -euo pipefail

# Recommended values – aggressive enough for monorepos and multiple editors.
MAX_USER_WATCHES=1048576    # ~1M – fits node_modules, .git, build artefacts
MAX_USER_INSTANCES=8192     # plenty for any reasonable workload
MAX_QUEUED_EVENTS=262144    # 16x default – avoids drops under bursts

CONF_FILE=/etc/sysctl.d/90-inotify.conf

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "This script needs root. Re-running under sudo..." >&2
    exec sudo -E "$0" "$@"
fi

echo "Current inotify limits:"
printf "  max_user_watches    = %s\n" "$(cat /proc/sys/fs/inotify/max_user_watches)"
printf "  max_user_instances  = %s\n" "$(cat /proc/sys/fs/inotify/max_user_instances)"
printf "  max_queued_events   = %s\n" "$(cat /proc/sys/fs/inotify/max_queued_events)"

echo ""
echo "Writing $CONF_FILE..."
cat >"$CONF_FILE" <<EOF
# Managed by fix-inotify-watches.sh
# Raised for editors (Sublime, VS Code, JetBrains) on large projects.
fs.inotify.max_user_watches = $MAX_USER_WATCHES
fs.inotify.max_user_instances = $MAX_USER_INSTANCES
fs.inotify.max_queued_events = $MAX_QUEUED_EVENTS
EOF
chmod 0644 "$CONF_FILE"

echo "Applying live..."
echo "$MAX_USER_WATCHES"   >/proc/sys/fs/inotify/max_user_watches
echo "$MAX_USER_INSTANCES" >/proc/sys/fs/inotify/max_user_instances
echo "$MAX_QUEUED_EVENTS"  >/proc/sys/fs/inotify/max_queued_events

# If sysctl is available, also reload through it (belt + braces; lets other
# tools relying on sysctl pick up the change immediately).
if command -v sysctl >/dev/null 2>&1; then
    sysctl -p "$CONF_FILE" >/dev/null
fi

echo ""
echo "New inotify limits:"
printf "  max_user_watches    = %s\n" "$(cat /proc/sys/fs/inotify/max_user_watches)"
printf "  max_user_instances  = %s\n" "$(cat /proc/sys/fs/inotify/max_user_instances)"
printf "  max_queued_events   = %s\n" "$(cat /proc/sys/fs/inotify/max_queued_events)"

echo ""
echo "Done. Existing editor processes need a restart to pick up the new limits."
