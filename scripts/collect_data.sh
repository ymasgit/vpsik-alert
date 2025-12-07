#!/bin/bash
DB="/opt/VPSIk-Alert/database/metrics.db"

# Create table if not exists
sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    cpu REAL,
    ram REAL,
    disk INTEGER
);"

# Get values
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
RAM=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
DISK=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Insert
sqlite3 "$DB" "INSERT INTO metrics (cpu, ram, disk) VALUES ($CPU, $RAM, $DISK);"

# Keep only last 30 days
sqlite3 "$DB" "DELETE FROM metrics WHERE timestamp < datetime('now', '-30 days');"
