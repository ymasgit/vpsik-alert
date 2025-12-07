#!/bin/bash
# VPSIk Alert v4.1 - With Clear Step Progress
# Fully resets config if reinstalling
set -euo pipefail

VERSION="4.1.0"
REPO_URL="https://github.com/ymasgit/vpsik-alert.git"
INSTALL_DIR="/opt/VPSIk-Alert"
TEMP_DIR="/tmp/vpsik-install-$$"
LOCK_FILE="/tmp/vpsik.install.lock"
INSTALL_LOG="/var/log/vpsik-installer.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

exec &> >(tee -a "$INSTALL_LOG" 2>/dev/null)
log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️ $1${NC}"; }
log_error() { echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}"; }
log_success() { echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $1${NC}"; }

# Clear step counter
STEP=0
TOTAL_STEPS=10

step() {
    ((STEP++))
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}▶ Step $STEP/$TOTAL_STEPS: $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Safety
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Run as root${NC}" >&2
    exit 1
fi

if [[ -f "$LOCK_FILE" ]]; then
    log_error "Installation in progress"
    exit 1
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║  ██╗   ██╗██████╗ ███████╗██╗██╗  ██╗                   ║
║  ██║   ██║██╔══██╗██╔════╝██║██║ ██╔╝                   ║
║  ██║   ██║██████╔╝███████╗██║█████╔╝                    ║
║  ╚██╗ ██╔╝██╔═══╝ ╚════██║██║██╔═██╗                    ║
║   ╚████╔╝ ██║     ███████║██║██║  ██╗                   ║
║    ╚═══╝  ╚═╝     ╚══════╝╚═╝╚═╝  ╚═╝                   ║
║                                                           ║
║              Professional VPS Monitoring                 ║
║                      Version 4.1                         ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}${GREEN}🚀 Installer with clear step progress${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# === MAIN STEPS ===

step "Check Internet"
timeout 5 curl -sf https://github.com > /dev/null || { log_error "No internet"; exit 1; }
log_success "Network OK"

step "Install Dependencies"
if [[ -f /etc/os-release ]]; then . /etc/os-release; fi
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
    apt-get update -qq
    apt-get install -y curl wget git jq bc python3 python3-pip python3-venv sqlite3 nginx openssl mailutils ssmtp fail2ban net-tools ufw lynis rkhunter chkrootkit
else
    log_error "Unsupported OS"
    exit 1
fi
log_success "Dependencies installed"

step "Create Directories"
rm -rf "$INSTALL_DIR"  # ⚠️ Force clean install
mkdir -p "$INSTALL_DIR"/{config,logs,scripts,dashboard}

step "Download Files from GitHub"
git clone --depth=1 "$REPO_URL" "$TEMP_DIR/src"
cp -r "$TEMP_DIR/src/scripts" "$INSTALL_DIR/" 2>/dev/null || true
cp -r "$TEMP_DIR/src/dashboard" "$INSTALL_DIR/" 2>/dev/null || true
chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
log_success "Files downloaded"

step "Configure Language & Notifications"
echo -e "${GREEN}1) English  2) Arabic  3) Spanish${NC}"
read -p "Choose language [1]: " lang
case "$lang" in 2) LANG="ar" ;; 3) LANG="es" ;; *) LANG="en" ;; esac

echo -e "${GREEN}1) Telegram  2) Email  3) Logs only${NC}"
read -p "Notification method [1]: " notif
case "$notif" in
    1)
        read -p "Bot Token: " BOT_TOKEN
        read -p "Chat ID: " CHAT_ID
        curl -sf "https://api.telegram.org/bot$BOT_TOKEN/getMe" | jq -e '.ok' >/dev/null || { log_error "Invalid Telegram token"; exit 1; }
        ;;
    2)
        read -p "Email: " EMAIL
        if [[ ! "$EMAIL" =~ @ ]]; then log_error "Invalid email"; exit 1; fi
        ;;
    *)
        BOT_TOKEN=""; CHAT_ID=""; EMAIL=""
        ;;
esac

step "Configure Dashboard"
read -p "Install Web Dashboard? (y/n) [y]: " dash
if [[ "${dash,,}" == "y" || -z "$dash" ]]; then
    DASH=true
    # Port
    while true; do
        DASHBOARD_PORT=$((10000 + RANDOM % 2001))
        if ! ss -tln | grep -q ":$DASHBOARD_PORT "; then break; fi
    done
    # Creds
    DASHBOARD_USER=$(openssl rand -hex 4)
    DASHBOARD_PASS=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' | head -c 12)
else
    DASH=false
fi

step "Generate Config"
cat > "$INSTALL_DIR/config/config.json" << EOF
{
  "language": "$LANG",
  "notifications": {
    "telegram": {"enabled": $([[ -n "$BOT_TOKEN" ]] && echo true || echo false), "token": "$BOT_TOKEN", "chat_id": "$CHAT_ID"},
    "email": {"enabled": $([[ -n "$EMAIL" ]] && echo true || echo false), "recipient": "$EMAIL"}
  },
  "dashboard": {"enabled": $DASH, "port": ${DASHBOARD_PORT:-8080}}
}
EOF
chmod 600 "$INSTALL_DIR/config/config.json"
log_success "Configuration saved"

step "Install Dashboard (venv + Flask)"
if [[ "$DASH" == true ]]; then
    python3 -m venv "$INSTALL_DIR/dashboard/venv"
    "$INSTALL_DIR/dashboard/venv/bin/pip" install --quiet flask
    log_success "Dashboard environment ready"
fi

step "Create System Services"
cat > /etc/systemd/system/vpsik-alert.timer << EOF
[Unit]
Description=VPSIk Timer
[Timer]
OnBootSec=1min
OnUnitActiveSec=300
[Install]
WantedBy=timers.target
EOF
cat > /etc/systemd/system/vpsik-alert.service << EOF
[Unit]
Description=VPSIk Monitor
[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/scripts/monitor.sh
EOF

if [[ "$DASH" == true ]]; then
    cat > /etc/systemd/system/vpsik-dashboard.service << EOF
[Unit]
Description=VPSIk Dashboard
[Service]
WorkingDirectory=$INSTALL_DIR/dashboard
Environment=DASHBOARD_PORT=$DASHBOARD_PORT
ExecStart=$INSTALL_DIR/dashboard/venv/bin/python app.py
Restart=always
EOF
fi

systemctl daemon-reload
log_success "Services created"

step "Start Services & Finalize"
systemctl enable --now vpsik-alert.timer
if [[ "$DASH" == true ]]; then
    systemctl enable --now vpsik-dashboard
    sleep 2
fi

# Summary
clear
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [[ "$DASH" == true ]]; then
    IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}🌐 Dashboard: http://$IP:$DASHBOARD_PORT${NC}"
    echo -e "${YELLOW}👤 User: $DASHBOARD_USER${NC}"
    echo -e "${YELLOW}🔑 Pass: $DASHBOARD_PASS${NC}"
    echo -e "${RED}⚠️ Save these credentials!${NC}"
fi
echo -e "${BLUE}👉 Run: vpsik status${NC}"
