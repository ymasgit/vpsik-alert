#!/bin/bash
CONFIG="/opt/VPSIk-Alert/config/config.json"
LOGS="/opt/VPSIk-Alert/logs/alerts.log"

CPU=$(top -bn1 | grep Cpu | awk '{print $2}')
RAM=$(free | grep Mem | awk '{print int($3/$2*100)}')
DISK=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if (( $(echo "$CPU > $(jq .thresholds.cpu.crit $CONFIG)" | bc -l) )); then
    echo "$(date): CPU CRITICAL $CPU%" >> $LOGS
    /opt/VPSIk-Alert/scripts/send_alert.sh "CPU Critical: $CPU%"
fi
# Similar for RAM, Disk, services, etc.
# Run collect_data.sh
/opt/VPSIk-Alert/scripts/collect_data.sh
