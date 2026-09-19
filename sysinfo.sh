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

