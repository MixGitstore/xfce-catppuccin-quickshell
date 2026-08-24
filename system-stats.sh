#!/usr/bin/env bash

# A short-lived sampler used only while the profile popup is visible.
# It avoids a resident monitor and reads the kernel interfaces directly.
read -r _ cpu_user cpu_nice cpu_system cpu_idle cpu_iowait cpu_irq cpu_softirq cpu_steal _ < /proc/stat
cpu_total_before=$((cpu_user + cpu_nice + cpu_system + cpu_idle + cpu_iowait + cpu_irq + cpu_softirq + cpu_steal))
cpu_idle_before=$((cpu_idle + cpu_iowait))

sleep 0.12

read -r _ cpu_user cpu_nice cpu_system cpu_idle cpu_iowait cpu_irq cpu_softirq cpu_steal _ < /proc/stat
cpu_total_after=$((cpu_user + cpu_nice + cpu_system + cpu_idle + cpu_iowait + cpu_irq + cpu_softirq + cpu_steal))
cpu_idle_after=$((cpu_idle + cpu_iowait))
cpu_delta=$((cpu_total_after - cpu_total_before))
idle_delta=$((cpu_idle_after - cpu_idle_before))
cpu_percent=0
if (( cpu_delta > 0 )); then
    cpu_percent=$((100 * (cpu_delta - idle_delta) / cpu_delta))
fi

memory_total_kib=0
memory_available_kib=0
while read -r memory_key memory_value _; do
    case "$memory_key" in
        MemTotal:) memory_total_kib=$memory_value ;;
        MemAvailable:) memory_available_kib=$memory_value ;;
    esac
done < /proc/meminfo
memory_used_kib=$((memory_total_kib - memory_available_kib))

disk_total=0
disk_used=0
mapfile -t disk_lines < <(df -B1 --output=size,used / 2>/dev/null)
if (( ${#disk_lines[@]} > 1 )); then
    read -r disk_total disk_used <<< "${disk_lines[${#disk_lines[@]} - 1]}"
fi

gpu_percent=-1
gpu_memory_used=0
gpu_memory_total=0

# NVIDIA exposes the most useful values through nvidia-smi. If the driver is
# unavailable, fall back to the generic DRM utilization interface.
if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_line=$(nvidia-smi \
        --query-gpu=utilization.gpu,memory.used,memory.total \
        --format=csv,noheader,nounits 2>/dev/null | sed -n '1p')
    if [[ $gpu_line =~ ^[[:space:]]*([0-9]+)[[:space:]]*,[[:space:]]*([0-9]+)[[:space:]]*,[[:space:]]*([0-9]+) ]]; then
        gpu_percent=${BASH_REMATCH[1]}
        gpu_memory_used=$((BASH_REMATCH[2] * 1024 * 1024))
        gpu_memory_total=$((BASH_REMATCH[3] * 1024 * 1024))
    fi
fi

if (( gpu_percent < 0 )); then
    # On some X11 installations the NV-CONTROL extension works even when
    # nvidia-smi telemetry is unavailable to an unprivileged process.
    if command -v nvidia-settings >/dev/null 2>&1 && [[ -n ${DISPLAY:-} ]]; then
        gpu_line=$(nvidia-settings -c "$DISPLAY" -q GPUUtilization -t 2>/dev/null)
        if [[ $gpu_line =~ graphics=([0-9]+) ]]; then
            gpu_percent=${BASH_REMATCH[1]}
        fi
    fi
fi

if (( gpu_percent < 0 )); then
    for drm_device in /sys/class/drm/card*/device; do
        if [[ -r "$drm_device/gpu_busy_percent" ]]; then
            read -r gpu_percent < "$drm_device/gpu_busy_percent"
            if [[ -r "$drm_device/mem_info_vram_used" ]]; then
                read -r gpu_memory_used < "$drm_device/mem_info_vram_used"
            fi
            if [[ -r "$drm_device/mem_info_vram_total" ]]; then
                read -r gpu_memory_total < "$drm_device/mem_info_vram_total"
            fi
            break
        fi
    done
fi

host_name="localhost"
if [[ -r /etc/hostname ]]; then
    read -r host_name < /etc/hostname
fi
if [[ -z $host_name ]]; then
    host_name=$(hostname 2>/dev/null)
fi
if [[ -z $host_name ]]; then
    host_name="localhost"
fi

printf 'CPU|%s\n' "$cpu_percent"
printf 'RAM|%s|%s\n' "$((memory_used_kib * 1024))" "$((memory_total_kib * 1024))"
printf 'GPU|%s|%s|%s\n' "$gpu_percent" "$gpu_memory_used" "$gpu_memory_total"
printf 'DISK|%s|%s\n' "$disk_used" "$disk_total"
printf 'HOST|%s\n' "$host_name"
