#!/usr/bin/env bash
# Installs or uninstalls the macOS LaunchAgents that drive Scripts/webkit-auto-update.sh (roadmap 0115, ADR-0127):
#   - studio.aemi.sunset.webkit-daily   (every day at 07:15: runs only when a newer WebKit security advisory exists)
#   - studio.aemi.sunset.webkit-weekly  (every Sunday at 04:00: full WebKit rebase, build, test, and two-variant release)
#
#   Scripts/install-webkit-schedule.sh install
#   Scripts/install-webkit-schedule.sh uninstall
#   Scripts/install-webkit-schedule.sh status
set -euo pipefail
cd "$(dirname "$0")/.."
repo="$PWD"
agents="$HOME/Library/LaunchAgents"
logs="$HOME/Library/Logs/Sunset"
uid="$(id -u)"

daily_label="studio.aemi.sunset.webkit-daily"
weekly_label="studio.aemi.sunset.webkit-weekly"
daily_plist="$agents/$daily_label.plist"
weekly_plist="$agents/$weekly_label.plist"

write_plist() {
    local label="$1" mode="$2" schedule_xml="$3" path="$4"
    cat > "$path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/bash</string>
        <string>$repo/Scripts/webkit-auto-update.sh</string>
        <string>--mode=$mode</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$repo</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StartCalendarInterval</key>
    $schedule_xml
    <key>StandardOutPath</key>
    <string>$logs/$label.out.log</string>
    <key>StandardErrorPath</key>
    <string>$logs/$label.err.log</string>
    <key>RunAtLoad</key>
    <false/>
    <key>Nice</key>
    <integer>10</integer>
</dict>
</plist>
EOF
}

case "${1:-status}" in
install)
    mkdir -p "$agents" "$logs"
    write_plist "$daily_label" "daily" \
        "<dict><key>Hour</key><integer>7</integer><key>Minute</key><integer>15</integer></dict>" \
        "$daily_plist"
    write_plist "$weekly_label" "weekly" \
        "<dict><key>Weekday</key><integer>0</integer><key>Hour</key><integer>4</integer><key>Minute</key><integer>0</integer></dict>" \
        "$weekly_plist"
    for plist in "$daily_plist" "$weekly_plist"; do
        label="$(basename "$plist" .plist)"
        launchctl bootout "gui/$uid/$label" 2>/dev/null || true
        launchctl bootstrap "gui/$uid" "$plist"
        echo "installed and loaded: $label ($plist)"
    done
    ;;
uninstall)
    for plist in "$daily_plist" "$weekly_plist"; do
        label="$(basename "$plist" .plist)"
        launchctl bootout "gui/$uid/$label" 2>/dev/null || true
        rm -f "$plist"
        echo "unloaded and removed: $label"
    done
    ;;
status)
    for label in "$daily_label" "$weekly_label"; do
        if launchctl print "gui/$uid/$label" >/dev/null 2>&1; then
            echo "$label: loaded"
        else
            echo "$label: not loaded"
        fi
    done
    ;;
*)
    echo "usage: Scripts/install-webkit-schedule.sh [install|uninstall|status]" >&2
    exit 2
    ;;
esac
