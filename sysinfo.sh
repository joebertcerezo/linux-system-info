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

# ============================================================
# CPU
# ============================================================

cpu_model=$(awk -F': ' '
    /^model name/ {
        print $2
        exit
    }
' /proc/cpuinfo)

[[ -z "$cpu_model" ]] && cpu_model="N/A"

# Logical CPUs
logical_cpus=$(grep -c '^processor' /proc/cpuinfo)

# Physical cores
physical_cores=$(awk '
    /^physical id/ {
        physical_ids[$4] = 1
    }

    END {
        count = 0

        for (id in physical_ids) {
            count++
        }

        print count
    }
' /proc/cpuinfo)

# If physical IDs are not available, use cpu cores
if [[ "$physical_cores" == "0" ]]; then
    cores_per_socket=$(awk '
        /^cpu cores/ {
            print $4
            exit
        }
    ' /proc/cpuinfo)

    physical_cores="${cores_per_socket:-$logical_cpus}"
else
    cores_per_socket=$(awk '
        /^cpu cores/ {
            print $4
            exit
        }
    ' /proc/cpuinfo)

    # physical id count above is number of sockets, not cores
    sockets=$(awk '
        /^physical id/ {
            ids[$4] = 1
        }

        END {
            count = 0

            for (id in ids) {
                count++
            }

            print count
        }
    ' /proc/cpuinfo)

    cores_per_socket=$(awk '
        /^cpu cores/ {
            print $4
            exit
        }
    ' /proc/cpuinfo)

    if [[ -n "$cores_per_socket" && -n "$sockets" ]]; then
        physical_cores=$((cores_per_socket * sockets))
    fi
fi

# CPU sockets
sockets=$(awk '
    /^physical id/ {
        ids[$4] = 1
    }

    END {
        count = 0

        for (id in ids) {
            count++
        }

        if (count == 0)
            count = 1

        print count
    }
' /proc/cpuinfo)

# Threads per core
if [[ "$physical_cores" -gt 0 ]]; then
    threads_per_core=$((logical_cpus / physical_cores))
else
    threads_per_core="N/A"
fi

# ============================================================
# CPU FREQUENCY
# ============================================================

current_frequency="N/A"
min_frequency="N/A"
max_frequency="N/A"
base_frequency="N/A"

CPUFREQ="/sys/devices/system/cpu/cpu0/cpufreq"

# Current frequency
if [[ -r "$CPUFREQ/scaling_cur_freq" ]]; then
    current_frequency=$(format_khz "$(cat "$CPUFREQ/scaling_cur_freq")")
elif [[ -r "$CPUFREQ/cpuinfo_cur_freq" ]]; then
    current_frequency=$(format_khz "$(cat "$CPUFREQ/cpuinfo_cur_freq")")
fi

# Minimum frequency
if [[ -r "$CPUFREQ/scaling_min_freq" ]]; then
    min_frequency=$(format_khz "$(cat "$CPUFREQ/scaling_min_freq")")
fi

# Maximum frequency
if [[ -r "$CPUFREQ/scaling_max_freq" ]]; then
    max_frequency=$(format_khz "$(cat "$CPUFREQ/scaling_max_freq")")
fi

# ============================================================
# CPU BASE FREQUENCY
# ============================================================

# Prefer lscpu CPU min/max information where available.
if command -v lscpu >/dev/null 2>&1; then

    cpu_base_mhz=$(lscpu | awk -F': *' '
        /^CPU min MHz:/ {
            print $2
            exit
        }
    ')

    # Some Intel systems expose the base frequency through
    # /sys/devices/system/cpu/cpuinfo_max_freq instead.
    if [[ -z "$cpu_base_mhz" ]] &&
       [[ -r /sys/devices/system/cpu/cpu0/cpufreq/base_frequency ]]; then

        base_frequency=$(format_khz \
            "$(cat /sys/devices/system/cpu/cpu0/cpufreq/base_frequency)")
    fi
fi

# For Intel systems, derive the advertised base frequency
# from the CPU model if it contains "@ X.XXGHz".
if [[ "$base_frequency" == "N/A" ]]; then

    model_base=$(printf '%s\n' "$cpu_model" |
        grep -oE '@ [0-9]+\.[0-9]+GHz' |
        sed 's/@ //')

    if [[ -n "$model_base" ]]; then
        base_frequency="$model_base"
    fi
fi

# ============================================================
# CPU USAGE
# ============================================================

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat

total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle1=$((idle + iowait))

sleep 0.25

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat

total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle2=$((idle + iowait))

total_delta=$((total2 - total1))
idle_delta=$((idle2 - idle1))

if (( total_delta > 0 )); then
    cpu_usage=$(awk \
        -v total="$total_delta" \
        -v idle="$idle_delta" '
        BEGIN {
            printf "%.1f%%", (1 - idle / total) * 100
        }
    ')
else
    cpu_usage="N/A"
fi

# ============================================================
# CPU CACHE
# ============================================================

l1_cache="N/A"
l2_cache="N/A"
l3_cache="N/A"

if command -v lscpu >/dev/null 2>&1; then

    l1_cache=$(lscpu | awk -F': *' '
        /^L1d cache:/ {
            print $2
            exit
        }
    ')

    l2_cache=$(lscpu | awk -F': *' '
        /^L2 cache:/ {
            print $2
            exit
        }
    ')

    l3_cache=$(lscpu | awk -F': *' '
        /^L3 cache:/ {
            print $2
            exit
        }
    ')
fi

[[ -z "$l1_cache" ]] && l1_cache="N/A"
[[ -z "$l2_cache" ]] && l2_cache="N/A"
[[ -z "$l3_cache" ]] && l3_cache="N/A"

# ============================================================
# CPU TEMPERATURE
# ============================================================

cpu_temperature="N/A"

for hwmon in /sys/class/hwmon/hwmon*; do

    [[ -d "$hwmon" ]] || continue

    name=$(get_file "$hwmon/name")

    for temp_input in "$hwmon"/temp*_input; do

        [[ -r "$temp_input" ]] || continue

        label_file="${temp_input%_input}_label"

        if [[ -r "$label_file" ]]; then
            label=$(<"$label_file")
        else
            label=""
        fi

        if [[ "$name" =~ [Cc][Pp][Uu] ]] ||
           [[ "$label" =~ [Cc][Pp][Uu] ]] ||
           [[ "$label" =~ Package ]] ||
           [[ "$label" =~ Core ]]; then

            temp=$(<"$temp_input")

            cpu_temperature=$(awk \
                -v temp="$temp" '
                BEGIN {
                    printf "%.1f °C", temp / 1000
                }
            ')

            break 2
        fi
    done
done

# ============================================================
# MEMORY
# ============================================================

mem_total=$(awk '
    /^MemTotal:/ {
        print $2 * 1024
    }
' /proc/meminfo)

mem_free=$(awk '
    /^MemFree:/ {
        print $2 * 1024
    }
' /proc/meminfo)

mem_available=$(awk '
    /^MemAvailable:/ {
        print $2 * 1024
    }
' /proc/meminfo)

mem_used=$((mem_total - mem_available))

mem_usage=$(awk \
    -v used="$mem_used" \
    -v total="$mem_total" '
    BEGIN {
        printf "%.1f%%", (used / total) * 100
    }
')

# ============================================================
# SWAP
# ============================================================

swap_total=$(awk '
    /^SwapTotal:/ {
        print $2 * 1024
    }
' /proc/meminfo)

swap_free=$(awk '
    /^SwapFree:/ {
        print $2 * 1024
    }
' /proc/meminfo)

swap_used=$((swap_total - swap_free))

if (( swap_total > 0 )); then

    swap_usage=$(awk \
        -v used="$swap_used" \
        -v total="$swap_total" '
        BEGIN {
            printf "%.1f%%", (used / total) * 100
        }
    ')

else
    swap_usage="0.0%"
fi

# ============================================================
# OUTPUT: SYSTEM
# ============================================================

printf '========================================\n'
printf '%27s\n' 'SYSTEM INFO'
printf '========================================\n'

subsection "HOSTNAME"

field "Hostname"     "$hostname"
field "OS"           "$os_name"
field "Kernel"       "$kernel"
field "Architecture" "$architecture"
field "Uptime"       "$uptime_display"

# ============================================================
# OUTPUT: CPU
# ============================================================

section "CPU"

field "CPU"                "$cpu_model"
field "Architecture"      "$architecture"
field "Socket(s)"          "$sockets"
field "CPU(s)"             "$logical_cpus"
field "Core(s) per Socket" "$cores_per_socket"
field "Thread(s) per Core" "$threads_per_core"
field "Physical Cores"     "$physical_cores"
field "Logical Cores"      "$logical_cpus"

printf '\n'

field "Base Frequency"    "$base_frequency"
field "Current Frequency" "$current_frequency"
field "Min Frequency"     "$min_frequency"
field "Max Frequency"     "$max_frequency"

printf '\n'

field "CPU Usage"   "$cpu_usage"
field "Temperature" "$cpu_temperature"

subsection "Cache"

field "L1 Cache" "$l1_cache"
field "L2 Cache" "$l2_cache"
field "L3 Cache" "$l3_cache"

# ============================================================
# OUTPUT: MEMORY
# ============================================================

section "MEMORY"

field "Total RAM"     "$(format_gib "$mem_total")"
field "Used RAM"      "$(format_gib "$mem_used")"
field "Free RAM"      "$(format_gib "$mem_free")"
field "Available RAM" "$(format_gib "$mem_available")"
field "Usage"         "$mem_usage"

subsection "Swap"

field "Total Swap" "$(format_gib "$swap_total")"
field "Used Swap"  "$(format_gib "$swap_used")"
field "Free Swap"  "$(format_gib "$swap_free")"
field "Usage"      "$swap_usage"

# ============================================================
# OUTPUT: MEMORY MODULES
# ============================================================

subsection "Memory Modules"

if ! command -v dmidecode >/dev/null 2>&1; then

    field "Status" "dmidecode not installed"

elif [[ "$EUID" -ne 0 ]]; then

    field "Status" "Run with sudo for RAM module details"

else

    dmidecode --type memory 2>/dev/null |
    awk '
    function reset() {
        slot = ""
        size = ""
        manufacturer = ""
        part_number = ""
        type = ""
        speed = ""
        configured_speed = ""
        valid = 0
    }

    function print_device() {

        if (!valid || size == "" || size == "No Module Installed")
            return

        printf "%-20s : %s\n", "Slot", slot
        printf "%-20s : %s\n", "Manufacturer", manufacturer
        printf "%-20s : %s\n", "Part Number", part_number
        printf "%-20s : %s\n", "Type", type
        printf "%-20s : %s\n", "Capacity", size
        printf "%-20s : %s\n", "Speed", speed

        if (configured_speed != "" &&
            configured_speed != "Unknown") {
            printf "%-20s : %s\n", \
                "Configured Speed", configured_speed
        }

        printf "\n"
    }

    BEGIN {
        in_device = 0
        reset()
    }

    /^Memory Device$/ {

        if (in_device)
            print_device()

        reset()
        in_device = 1
        next
    }

    !in_device {
        next
    }

    /^[[:space:]]*Size:/ {
        value = $0
        sub(/^[^:]*:[[:space:]]*/, "", value)

        size = value

        if (size != "" && size != "No Module Installed")
            valid = 1

        next
    }

    /^[[:space:]]*Locator:/ {
        value = $0
        sub(/^[^:]*:[[:space:]]*/, "", value)
        slot = value
        next
    }

    /^[[:space:]]*Manufacturer:/ {
        value = $0
        sub(/^[^:]*:[[:space:]]*/, "", value)
        manufacturer = value
        next
    }

    /^[[:space:]]*Part Number:/ {
        value = $0
        sub(/^[^:]*:[[:space:]]*/, "", value)
        part_number = value
        next
    }

    /^[[:space:]]*Type:/ {
        value = $0
        sub(/^[^:]*:[[:space:]]*/, "", value)
        type = value
        next
    }

    /^[[:space:]]*Speed:/ {
        value = $0
        sub(/^[^:]*:[[:space:]]*/, "", value)
        speed = value
        next
    }

    /^[[:space:]]*Configured Memory Speed:/ {
        value = $0
        sub(/^[^:]*:[[:space:]]*/, "", value)
        configured_speed = value
        next
    }

    END {
        if (in_device)
            print_device()
    }
    '

fi

# ============================================================
# OUTPUT: MOTHERBOARD
# ============================================================

section "MOTHERBOARD"

field "Manufacturer"  "$(get_file "$DMI/board_vendor")"
field "Model"         "$(get_file "$DMI/board_name")"
field "Version"       "$(get_file "$DMI/board_version")"
field "Serial Number" "$(get_file "$DMI/board_serial")"
field "Asset Tag"     "$(get_file "$DMI/board_asset_tag")"

# ============================================================
# OUTPUT: BIOS
# ============================================================

section "BIOS"

field "Vendor"       "$(get_file "$DMI/bios_vendor")"
field "Version"      "$(get_file "$DMI/bios_version")"
field "Release Date" "$(get_file "$DMI/bios_date")"
field "Release"      "$(get_file "$DMI/bios_release")"

printf '\n'
