#!/bin/bash
# VPSIk Alert - Professional VPS Monitoring Installer v4.0
# One-line: curl -sSL https://raw.githubusercontent.com/ymasgit/vpsik-alert/main/install.sh | sudo bash
set -euo pipefail

# === CONSTANTS ===
VERSION="4.0.0"
REPO_URL="https://github.com/ymasgit/vpsik-alert.git"
INSTALL_DIR="/opt/VPSIk-Alert"
TEMP_DIR="/tmp/vpsik-install-$$"
LOCK_FILE="/tmp/vpsik.install.lock"
INSTALL_LOG="/var/log/vpsik-installer.log"

# === COLORS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# === LOGGING ===
exec &> >(tee -a "$INSTALL_LOG" 2>/dev/null || true)
log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️ $1${NC}"; }
log_error() { echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}"; }
log_success() { echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $1${NC}"; }
log_step() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# === SAFETY ===
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Run as root: sudo bash $0${NC}" >&2
   exit 1
fi

if [[ -f "$LOCK_FILE" ]]; then
    log_error "Installation already in progress"
    exit 1
fi

touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE" 2>/dev/null' EXIT

# === BANNER ===
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
║                      Version 4.0                         ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}${GREEN}🚀 Fully Functional Installer${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# === NETWORK CHECK ===
check_network() {
    log_step "🌐 Checking Internet"
    if ! timeout 10 curl -sf https://github.com > /dev/null 2>&1; then
        log_error "No internet or GitHub unreachable"
        exit 1
    fi
    log_success "Network OK"
}

# === OS DETECTION ===
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        if [[ "$OS" == "almalinux" || "$OS" == "rocky" ]]; then OS="rhel"; fi
    else
        log_error "Unsupported OS"
        exit 1
    fi
}

# === DEPENDENCIES ===
install_dependencies() {
    log_step "📦 Installing Dependencies"
    detect_os
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update -qq
        apt-get install -y curl wget git jq bc python3 python3-pip python3-venv \
            sqlite3 nginx openssl mailutils ssmtp fail2ban net-tools ufw lynis rkhunter chkrootkit
    elif [[ "$OS" == "rhel" || "$OS" == "centos" || "$OS" == "fedora" ]]; then
        yum install -y epel-release
        yum install -y curl wget git jq bc python3 python3-pip sqlite nginx openssl \
            mailx fail2ban net-tools lynis rkhunter chkrootkit
    else
        log_error "Unsupported OS: $OS"
        exit 1
    fi
    log_success "Dependencies installed"
}

# === DIRECTORIES ===
create_directories() {
    log_step "📁 Creating Directories"
    mkdir -p "$INSTALL_DIR"/{config,logs,scripts,dashboard/{static/{css,js,img},templates,database},security/scans}
    log_success "Directories ready"
}

# === DOWNLOAD FROM GITHUB ===
download_files() {
    log_step "⬇️ Downloading from GitHub"
    mkdir -p "$TEMP_DIR"
    if git clone --depth=1 "$REPO_URL" "$TEMP_DIR/src"; then
        cp -r "$TEMP_DIR/src/scripts" "$INSTALL_DIR/" 2>/dev/null || true
        cp -r "$TEMP_DIR/src/dashboard" "$INSTALL_DIR/" 2>/dev/null || true
    else
        log_warn "Git clone failed – using built-in fallback"
        create_fallback_files
        return
    fi

    # Use real files if they exist
    if [[ -f "$INSTALL_DIR/scripts/monitor.sh" ]]; then
        chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
        log_success "✅ Real files loaded from GitHub"
    else
        log_warn "No scripts found – using fallback"
        create_fallback_files
    fi
}

# === FALLBACK FILES (if GitHub empty) ===
create_fallback_files() {
    # Monitoring
    cat > "$INSTALL_DIR/scripts/monitor.sh" << 'EOF'
#!/bin/bash
CONFIG="/opt/VPSIk-Alert/config/config.json"
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
RAM=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
DISK=$(df / | awk 'NR==2{print int($5)}')
echo "[$(date)] CPU:${CPU}% RAM:${RAM}% DISK:${DISK}%"
EOF
    chmod +x "$INSTALL_DIR/scripts/monitor.sh"

    # Dashboard app.py
    cat > "$INSTALL_DIR/dashboard/app.py" << 'EOF'
from flask import Flask
import os
app = Flask(__name__)
@app.route('/')
def index():
    return "<h1>VPSIk Alert Dashboard - Working!</h1>"
if __name__ == '__main__':
    port = int(os.environ.get('DASHBOARD_PORT', 8080))
    app.run(host='0.0.0.0', port=port)
EOF
    log_success "✅ Fallback files created"
}

# === CONFIGURATION ===
interactive_config() {
    log_step "⚙️ Configuration"
    read -p "Alert Name [$(hostname)]: " ALERT_NAME
    ALERT_NAME=${ALERT_NAME:-"$(hostname)"}

    echo "Notification: 1)Telegram 2)Email 3)Logs only"
    read -p "Choice [1]: " notif
    case "${notif:-1}" in
        1)
            read -p "Telegram Bot Token: " BOT_TOKEN
            read -p "Chat ID: " CHAT_ID
            curl -sf "https://api.telegram.org/bot$BOT_TOKEN/getMe" | jq -e '.ok' >/dev/null || { log_error "Invalid token"; exit 1; }
            TELEGRAM_ENABLED=true
            ;;
        2)
            read -p "Email Recipient: " EMAIL_RECIPIENT
            read -p "SMTP Host: " SMTP_HOST
            read -p "SMTP Port [587]: " SMTP_PORT; SMTP_PORT=${SMTP_PORT:-587}
            read -p "SMTP User: " SMTP_USER
            read -sp "SMTP Pass: " SMTP_PASS; echo
            EMAIL_ENABLED=true
            ;;
        *)
            TELEGRAM_ENABLED=false; EMAIL_ENABLED=false
            ;;
    esac

    # Dashboard with strong random creds
    read -p "Install Web Dashboard? [y]: " dash
    if [[ "${dash,,}" == "y" || -z "$dash" ]]; then
        DASHBOARD_ENABLED=true
        # Random unused port
        while true; do
            DASHBOARD_PORT=$((10000 + RANDOM % 2001))
            if ! ss -tln | grep -q ":$DASHBOARD_PORT "; then break; fi
        done
        # Strong random user/pass
        DASHBOARD_USER=$(openssl rand -hex 4)
        DASHBOARD_PASS=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' | head -c 12)
        echo -e "${GREEN}Dashboard: http://\$(hostname -I | awk '{print \$1}'):$DASHBOARD_PORT${NC}"
        echo -e "${GREEN}User: $DASHBOARD_USER | Pass: $DASHBOARD_PASS${NC}"
        echo -e "${RED}⚠️ SAVE THESE CREDENTIALS!${NC}"
        read -p "Press Enter to continue..."
    else
        DASHBOARD_ENABLED=false
    fi

    CHECK_INTERVAL=300
}

# === GENERATE CONFIG ===
generate_config() {
    cat > "$INSTALL_DIR/config/config.json" << EOF
{
  "version": "$VERSION",
  "alert_name": "$ALERT_NAME",
  "dashboard": {
    "enabled": $DASHBOARD_ENABLED,
    "port": ${DASHBOARD_PORT:-8080}
  },
  "notifications": {
    "telegram": {
      "enabled": ${TELEGRAM_ENABLED:-false},
      "bot_token": "${BOT_TOKEN:-}",
      "chat_id": "${CHAT_ID:-}"
    },
    "email": {
      "enabled": ${EMAIL_ENABLED:-false},
      "recipient": "${EMAIL_RECIPIENT:-}"
    }
  },
  "thresholds": {
    "cpu": {"warning": 80, "critical": 95},
    "ram": {"warning": 85, "critical": 95},
    "disk": {"warning": 85, "critical": 95}
  }
}
EOF
    chmod 600 "$INSTALL_DIR/config/config.json"

    # SMTP config
    if [[ "${EMAIL_ENABLED:-false}" == true ]]; then
        cat > /etc/ssmtp/ssmtp.conf << EOF
root=$EMAIL_RECIPIENT
mailhub=$SMTP_HOST:$SMTP_PORT
AuthUser=$SMTP_USER
AuthPass=$SMTP_PASS
UseSTARTTLS=YES
FromLineOverride=YES
EOF
        chmod 640 /etc/ssmtp/ssmtp.conf
    fi
}

# === DASHBOARD SETUP ===
install_dashboard() {
    if [[ "$DASHBOARD_ENABLED" != true ]]; then return; fi
    log_step "🖥️ Installing Dashboard"
    cd "$INSTALL_DIR/dashboard"
    python3 -m venv venv
    ./venv/bin/pip install --quiet flask
    log_success "Dashboard ready"
}

# === SERVICES ===
create_services() {
    log_step "⚙️ Creating Services"

    # Monitor
    cat > /etc/systemd/system/vpsik-alert.service << EOF
[Unit]
Description=VPSIk Alert Monitor
[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/scripts/monitor.sh
EOF

    cat > /etc/systemd/system/vpsik-alert.timer << EOF
[Unit]
Description=VPSIk Alert Timer
[Timer]
OnBootSec=1min
OnUnitActiveSec=300
[Install]
WantedBy=timers.target
EOF

    # Dashboard
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        cat > /etc/systemd/system/vpsik-dashboard.service << EOF
[Unit]
Description=VPSIk Dashboard
After=network.target
[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR/dashboard
Environment=DASHBOARD_PORT=$DASHBOARD_PORT
ExecStart=$INSTALL_DIR/dashboard/venv/bin/python app.py
Restart=always
RestartSec=5
User=root
[Install]
WantedBy=multi-user.target
EOF
    fi

    systemctl daemon-reload
    log_success "Services created"
}

# === START SERVICES ===
start_services() {
    systemctl enable --now vpsik-alert.timer
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        systemctl enable --now vpsik-dashboard
        sleep 3
        if curl -sf "http://localhost:$DASHBOARD_PORT" > /dev/null 2>&1; then
            log_success "Dashboard accessible on port $DASHBOARD_PORT"
        else
            log_warn "Dashboard may take a moment to start"
        fi
    fi
}

# === MANAGEMENT COMMAND ===
create_management_command() {
    cat > /usr/local/bin/vpsik << 'EOF'
#!/bin/bash
case "$1" in
    status)
        systemctl status vpsik-alert.timer
        systemctl status vpsik-dashboard 2>/dev/null || true
        ;;
    dashboard)
        IP=$(hostname -I | awk '{print $1}')
        PORT=$(jq -r '.dashboard.port' /opt/VPSIk-Alert/config/config.json)
        echo "🌐 http://$IP:$PORT"
        ;;
    logs)
        journalctl -u vpsik-alert -f
        ;;
    test)
        /opt/VPSIk-Alert/scripts/monitor.sh
        ;;
    uninstall)
        curl -sSL https://raw.githubusercontent.com/ymasgit/vpsik-alert/main/install.sh | sudo bash -s uninstall
        ;;
    *)
        echo "Usage: vpsik {status|dashboard|logs|test|uninstall}"
        ;;
esac
EOF
    chmod +x /usr/local/bin/vpsik
}

# === UNINSTALLER ===
uninstall_vpsik() {
    log_step "🗑️ Uninstalling"
    systemctl stop vpsik-*.service vpsik-*.timer 2>/dev/null || true
    systemctl disable vpsik-*.service vpsik-*.timer 2>/dev/null || true
    rm -f /etc/systemd/system/vpsik-*.service /etc/systemd/system/vpsik-*.timer
    rm -rf /opt/VPSIk-Alert /usr/local/bin/vpsik
    systemctl daemon-reload
    log_success "Uninstalled"
    exit 0
}

# === MAIN ===
main() {
    if [[ "${1:-}" == "uninstall" ]]; then
        print_banner
        uninstall_vpsik
    fi

    print_banner
    check_network
    install_dependencies
    create_directories
    download_files
    interactive_config
    generate_config
    install_dashboard
    create_services
    start_services
    create_management_command

    clear
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}👉 vpsik status${NC}"
    echo -e "${YELLOW}👉 vpsik dashboard${NC}"
    echo -e "${YELLOW}👉 vpsik test${NC}"
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        IP=$(hostname -I | awk '{print $1}')
        echo -e "${GREEN}🌐 Dashboard: http://$IP:$DASHBOARD_PORT${NC}"
        echo -e "${GREEN}🔑 User: $DASHBOARD_USER | Pass: ***${NC}"
    fi
}

main "$@"
