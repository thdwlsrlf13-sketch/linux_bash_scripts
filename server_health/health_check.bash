#!/bin/bash

CPU_WARN=80
MEM_WARN=85
DISK_WARN=90
INODE_WARN=90

SERVICES=("sshd" "chronyd")

PORTS=(22)

GATEWAY=$(ip route | awk '/default/{print $3; exit}')


print_ok() {
	echo "[ok] $1"
}

print_warn() {
	echo "[warn] $1"
}

print_fail() {
	echo "[fail] $1"
}

#cpu health check

check_cpu() {
	read cpu user pnice system idle iowait irq softirq steal guest guest_nice < /proc/stat

	total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
	idle1=$((idle + iowait))

	sleep 1

	read cpu user pnice system idle iowait irq softirq steal guest guest_nice < /proc/stat

	total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
	idle2=$((idle + iowait))

	total_diff=$((total2 - total1))
	idle_diff=$((idle2 - idle1))

	if ((total_diff == 0)); then
		print_fail "CPU usage calculation failed"
		return
	fi

	cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))

	if ((cpu_usage >= CPU_WARN)); then
		print_warn "CPU Usage: ${cpu_usage}%"
	else
		print_ok "CPU Usage: ${cpu_usage}%"
	fi
}

#Load Average check

check_load() {
	load1=$(awk '{print $1}' /proc/loadavg)
	cpu_count=$(nproc)

	echo "[INFO] Load Average(1m): $load1 / CPU Cores: $cpu_count"
}

check_memory() {
	total=$(free -m | awk '/^Mem:/ {print $2}')
	available=$(free -m | awk '/^Mem:/ {print $7}')
	
	used=$((total - available))
	mem_usage=$((used * 100 / total))

	if ((mem_usage >= MEM_WARN)); then
		print_warn "Memory Usage: ${mem_usage}% (${used}MB / ${total}MB)"
	else
		print_ok "Memory Usage: ${mem_usage}% (${used}MB / ${total}MB)"
	fi
}

check_disk() {
	df -P -x tmpfs | tail -n +2 |
	while read filesystem blocks used available capacity mountpoint
	do
		usage=${capacity%\%}

		if ((usage >= DISK_WARN)); then
			print_warn "Disk $mountpoint: ${usage}%"
		else
			print_ok "Disk $mountpoint: ${usage}%"
		fi
	done
}

echo "==================================="
echo	"Server Health Check"
echo	"Hostname: $(hostname)"
echo	"Date: $(date)"
echo "==================================="


echo "--------cpu--------"
check_cpu

echo "--------load avg--------"
check_load

echo "--------memory--------"
check_memory

echo "--------disk--------"
check_disk
