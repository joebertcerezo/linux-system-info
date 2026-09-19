#!/usr/bin/env bash

set -u

DMI="/sys/devices/virtual/dmi/id"

# ============================================================
# HELPERS
# ============================================================

get_file() {
    local file="$1"

    if [[ -r "$file" ]]; then
        local value
        value=$(<"$file")
        [[ -n "$value" ]] && printf '%s' "$value" || printf '%s' "N/A"
    else
        printf '%s' "N/A"
    fi
}

field() {
    printf '%-20s : %s\n' "$1" "$2"
}

section() {
    printf '\n'
    printf '========================================\n'
    printf '%27s\n' "$1"
    printf '========================================\n'
}

subsection() {
    printf '\n'
    printf '%s\n' "$1"
    printf '%s\n' "----------------------------------------"
}

format_gib() {
    awk -v bytes="$1" '
        BEGIN {
            printf "%.1f GiB", bytes / 1024 / 1024 / 1024
        }
    '
}

format_khz() {
    awk -v khz="$1" '
        BEGIN {
            printf "%.2f GHz", khz / 1000000
        }
    '
}

# ============================================================
# SYSTEM
# ============================================================

hostname=$(hostname)

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    os_name="${PRETTY_NAME:-${NAME:-N/A}}"
else
    os_name="N/A"
fi

kernel=$(uname -r)
architecture=$(uname -m)

# Uptime
uptime_seconds=$(awk '{print int($1)}' /proc/uptime)

uptime_days=$((uptime_seconds / 86400))
uptime_hours=$(((uptime_seconds % 86400) / 3600))
uptime_minutes=$(((uptime_seconds % 3600) / 60))

if (( uptime_days > 0 )); then
    uptime_display="${uptime_days} days, ${uptime_hours} hours"
elif (( uptime_hours > 0 )); then
    uptime_display="${uptime_hours} hours, ${uptime_minutes} minutes"
else
    uptime_display="${uptime_minutes} minutes"
fi

