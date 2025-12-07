#!/bin/bash
MSG="$1"
CONFIG="/opt/VPSIk-Alert/config/config.json"
TOKEN=$(jq -r .notifications.telegram.token $CONFIG)
CHAT=$(jq -r .notifications.telegram.chat_id $CONFIG)
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d chat_id="$CHAT" -d text="$MSG" > /dev/null
# Add email/discord if enabled
