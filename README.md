# LINUX SYSTEM INFO

A lightweight Bash utility for displaying detailed Linux system and hardware information in a clean, terminal-friendly format.

The script collects information directly from Linux system interfaces such as `/proc`, `/sys`, DMI/SMBIOS, and standard Linux utilities.

## Features

* 🖥️ System information

  * Hostname
  * Operating system
  * Kernel version
  * CPU architecture
  * System uptime

* ⚙️ CPU information

  * CPU model
  * CPU sockets
  * Logical CPUs
  * Physical cores
  * Cores per socket
  * Threads per core
  * Base frequency
  * Current frequency
  * Minimum frequency
  * Maximum frequency
  * CPU usage
  * CPU temperature

* 🧠 CPU cache

  * L1 cache
  * L2 cache
  * L3 cache

* 💾 Memory information

  * Total RAM
  * Used RAM
  * Free RAM
  * Available RAM
  * RAM usage
  * Swap usage

* 🧩 Memory modules

  * RAM slot
  * Manufacturer
  * Part number
  * Memory type
  * Capacity
  * Speed

* 🔧 Motherboard information

  * Manufacturer
  * Model
  * Version
  * Serial number
  * Asset tag

* 🔐 BIOS information

  * Vendor
  * Version
  * Release date
  * BIOS release

---

## Example Output

```text
========================================
                SYSTEM INFO
========================================

HOSTNAME
----------------------------------------
Hostname             : jlcerezo
OS                   : Ubuntu 24.04.4 LTS
Kernel               : 7.0.0-30-generic
Architecture         : x86_64
Uptime               : 14 hours, 30 minutes

========================================
                        CPU
========================================
CPU                  : Intel(R) Core(TM) i5-10400 CPU @ 2.90GHz
Architecture         : x86_64
Socket(s)            : 1
CPU(s)               : 12
Core(s) per Socket   : 6
Thread(s) per Core   : 2
Physical Cores       : 6
Logical Cores        : 12

Base Frequency       : 2.90 GHz
Current Frequency    : 4.00 GHz
Minimum Frequency    : 0.80 GHz
Maximum Frequency    : 4.30 GHz

CPU Usage            : 1.3%
Temperature          : 38.0 °C

Cache
----------------------------------------
L1 Cache             : 192 KiB (6 instances)
L2 Cache             : 1.5 MiB (6 instances)
L3 Cache             : 12 MiB (1 instance)

========================================
                     MEMORY
========================================
Total RAM            : 14.5 GiB
Used RAM             : 9.4 GiB
Free RAM             : 0.5 GiB
Available RAM        : 5.1 GiB
Usage                : 64.7%

Swap
----------------------------------------
Total Swap           : 4.0 GiB
Used Swap            : 0.0 GiB
Free Swap            : 4.0 GiB
Usage                : 0.0%

Memory Modules
----------------------------------------
Slot                 : DIMM_A1
Manufacturer         : Kingston
Part Number          : KF3200C16D4/16
Type                 : DDR4
Capacity             : 16 GB
Speed                : 3200 MT/s
Configured Speed     : 3200 MT/s

Slot                 : DIMM_B1
Manufacturer         : Kingston
Part Number          : KF3200C16D4/16
Type                 : DDR4
Capacity             : 16 GB
Speed                : 3200 MT/s
Configured Speed     : 3200 MT/s

========================================
                MOTHERBOARD
========================================
Manufacturer         : ASUSTeK COMPUTER INC.
Model                : PRIME H510M-K
Version              : Rev 1.xx
Serial Number        : N/A
Asset Tag            : Default string

========================================
                       BIOS
========================================
Vendor               : American Megatrends Inc.
Version              : 0820
Release Date         : 04/27/2021
Release              : 8.20
```

> Hardware values in the example above are machine-specific and will differ depending on the system running the script.

---

## Requirements

The script is designed for Linux systems with:

* Bash
* `/proc` filesystem
* `/sys` filesystem
* DMI/SMBIOS information
* `awk`
* `sed`
* `grep`
* `hostname`
* `uname`

The following utilities are used when available:

* `lscpu` — CPU and cache information
* `dmidecode` — physical RAM module information

### Recommended packages

On Ubuntu/Debian:

```bash
sudo apt install util-linux dmidecode
```

On Fedora:

```bash
sudo dnf install util-linux dmidecode
```

`lscpu` is normally included with `util-linux`.

---

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/linux-system-info.git
```

Enter the project directory:

```bash
cd linux-system-info
```

Make the script executable:

```bash
chmod +x sysinfo.sh
```

---

## Usage

Run the script:

```bash
./sysinfo.sh
```

For complete hardware information, including physical RAM modules:

```bash
sudo ./sysinfo.sh
```

The script does not require `sudo` for most system information.

`sudo` is primarily required because access to some DMI/SMBIOS information, particularly physical memory module details, may be restricted by the operating system.

---

## Information Sources

The script intentionally uses Linux's existing system interfaces rather than depending on a large hardware-detection framework.

### System

```text
/etc/os-release
/proc/uptime
uname
hostname
```

Used for:

* Operating system
* Kernel version
* Architecture
* Hostname
* Uptime

### CPU

```text
/proc/cpuinfo
/proc/stat
/sys/devices/system/cpu/
```

Used for:

* CPU model
* CPU topology
* CPU cores
* Threads
* CPU usage
* CPU frequency information

### Memory

```text
/proc/meminfo
```

Used for:

* Total RAM
* Used RAM
* Free RAM
* Available RAM
* Swap

### CPU Temperature

```text
/sys/class/hwmon/
```

Used to detect available CPU temperature sensors.

### CPU Cache

```bash
lscpu
```

Used for:

* L1 cache
* L2 cache
* L3 cache

### Motherboard and BIOS

```text
/sys/devices/virtual/dmi/id/
```

Used for:

* Motherboard manufacturer
* Motherboard model
* Board version
* Board serial number
* BIOS vendor
* BIOS version
* BIOS release date

### Memory Modules

```bash
dmidecode --type memory
```

Used for:

* DIMM slot
* Manufacturer
* Part number
* Memory type
* Capacity
* Speed

---

## Why `/proc` and `/sys`?

Linux exposes a large amount of runtime and hardware information through virtual filesystems.

This project uses those interfaces directly where possible.

For example:

```bash
cat /proc/cpuinfo
```

provides detailed processor information.

```bash
cat /proc/meminfo
```

provides memory statistics.

```bash
cat /sys/devices/virtual/dmi/id/board_name
```

provides the motherboard model.

This makes the script lightweight and avoids requiring a large external dependency for basic system information.

---

## Memory Usage

The script reports several different memory values:

```text
Total RAM
Used RAM
Free RAM
Available RAM
```

`Used RAM` is calculated as:

```text
Total RAM - Available RAM
```

`Available RAM` is generally more useful than `Free RAM` when determining whether Linux has enough memory available for new applications.

Linux intentionally uses otherwise-unused memory for filesystem caches and other purposes, so a low `Free RAM` value does not necessarily mean the system is running out of memory.

---

## CPU Frequency

The script reports:

```text
Base Frequency
Current Frequency
Minimum Frequency
Maximum Frequency
```

These values can vary depending on:

* CPU model
* CPU frequency driver
* CPU governor
* BIOS configuration
* Power-management settings
* Current system load

The current frequency is therefore a runtime value and may change continuously.

---

## CPU Temperature

CPU temperature is obtained through Linux hardware-monitoring interfaces:

```text
/sys/class/hwmon/
```

Sensor availability depends on:

* CPU
* Motherboard
* Kernel
* Hardware monitoring driver
* BIOS/firmware

If no suitable sensor is exposed, the script displays:

```text
Temperature          : N/A
```

---

## Memory Module Information

Physical DIMM information is obtained using:

```bash
sudo dmidecode --type memory
```

Some systems restrict access to DMI/SMBIOS information when running without root privileges.

Therefore:

```bash
./sysinfo.sh
```

may display:

```text
Memory Modules
----------------------------------------
Status               : Run with sudo for RAM module details
```

Running:

```bash
sudo ./sysinfo.sh
```

allows the script to attempt to retrieve the physical memory module information.

---

## Compatibility

The script is primarily intended for Linux distributions using standard Linux `/proc`, `/sys`, and DMI/SMBIOS interfaces.

It should work on distributions such as:

* Ubuntu
* Debian
* Fedora
* Arch Linux
* Linux Mint
* openSUSE
* RHEL-based distributions

Hardware-specific information may vary depending on the kernel, drivers, firmware, motherboard, and CPU.

---

## Limitations

Hardware information exposed by Linux is not always consistent across systems.

For example:

* Some systems do not expose motherboard serial numbers.
* Some systems do not expose product UUIDs.
* CPU temperature sensors may not be available.
* CPU frequency interfaces vary between drivers.
* RAM module information may require root privileges.
* Virtual machines may expose incomplete or virtualized hardware information.
* Some cache information is obtained through `lscpu`.
* BIOS/DMI information depends on SMBIOS support.

When information cannot be obtained, the script reports:

```text
N/A
```

rather than failing.

---

## Project Structure

```text
linux-system-info/
├── sysinfo.sh
└── README.md
```

---

## Design Goals

The project aims to be:

* Lightweight
* Dependency-conscious
* Easy to read
* Easy to modify
* Terminal-friendly
* Linux-native
* Useful for troubleshooting and system inspection

The script favors Linux's built-in interfaces such as `/proc`, `/sys`, and DMI/SMBIOS instead of relying entirely on external system-information applications.

---

## Future Improvements

Potential additions include:

* GPU information
* GPU temperature
* Disk and partition information
* NVMe information
* Disk health / SMART information
* Network interfaces
* IP addresses
* Network link speed
* Wi-Fi information
* Fan speeds
* Motherboard temperatures
* Battery information for laptops
* CPU governor
* CPU frequency scaling driver
* Load average
* Process information
* Disk usage
* Filesystem information
* Linux distribution detection improvements
* Optional JSON output
* Optional compact output
* Colored terminal output
* Command-line arguments

Example future usage:

```bash
./sysinfo.sh
./sysinfo.sh --cpu
./sysinfo.sh --memory
./sysinfo.sh --motherboard
./sysinfo.sh --all
./sysinfo.sh --json
```

---

## Disclaimer

Hardware information is obtained from interfaces provided by the Linux kernel, firmware, DMI/SMBIOS, and available system utilities.

Reported values may vary depending on hardware, firmware, kernel version, drivers, virtualization, and system configuration.
