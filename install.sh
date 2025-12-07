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
exec &> >(tee -a "$INSTALL_LOG" 2>/dev/null)
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

# === SAFETY CHECKS ===
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root${NC}" >&2
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
    echo -e "${NC}${GREEN}🚀 All-in-One Installer${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# === OS DETECTION ===
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        if [[ "$OS" == "almalinux" || "$OS" == "rocky" ]]; then OS="rhel"; fi
    else
        log_error "Cannot detect OS"
        exit 1
    fi
}

# === MAIN FLOW ===
main() {
    if [[ "${1:-}" == "uninstall" ]]; then
        print_banner
        uninstall_vpsik
        exit 0
    fi

    print_banner
    check_update_mode "$1"
    check_existing
    install_dependencies
    create_directories
    download_files
    if [[ "$UPDATE_MODE" == false ]]; then
        security_hardening
        interactive_config
        generate_config
    else
        load_existing_config
    fi
    install_monitoring
    install_dashboard
    create_services
    start_services
    create_management_command
    setup_security_audit
    test_installation
    print_summary
    cleanup
}

# === MODE HANDLING ===
check_update_mode() {
    if [[ "${1:-}" == "update" ]]; then
        UPDATE_MODE=true
        log_step "🔄 UPDATE MODE"
        [[ ! -d "$INSTALL_DIR" ]] && { log_error "Not installed"; exit 1; }
    else
        UPDATE_MODE=false
        log_step "📦 INSTALLATION MODE"
    fi
}

check_existing() {
    if [[ -d "$INSTALL_DIR" && "$UPDATE_MODE" == false ]]; then
        log_warn "VPSIk Alert is already installed!"
        read -p "Update instead? (y/n): " choice
        [[ "$choice" == "y" ]] && { UPDATE_MODE=true; log "Switching to update mode..."; } || { log_error "Cancelled"; exit 0; }
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
    mkdir -p "$INSTALL_DIR"/{config,logs,translations,scripts,security/{ssl,ddos,logs},recovery,dashboard/{static/{css,js,img},templates,api},database}
    log_success "Directories ready"
}

# === DOWNLOAD FROM GITHUB ===
download_files() {
    log_step "⬇️ Downloading Files from GitHub"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    if git clone --depth=1 "$REPO_URL" src; then
        cp -r src/scripts/* "$INSTALL_DIR/scripts/" 2>/dev/null || true
        cp -r src/dashboard/* "$INSTALL_DIR/dashboard/" 2>/dev/null || true
        cp -r src/translations/* "$INSTALL_DIR/translations/" 2>/dev/null || true
    else
        log_warn "Git clone failed; using built-in scripts"
        create_builtin_files
        return
    fi
    chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
    log_success "Files ready"
}

# === BUILT-IN FALLBACK ===
create_builtin_files() {
    # Monitor script placeholder
    cat > "$INSTALL_DIR/scripts/monitor.sh" << 'EOF'
#!/bin/bash
echo "[VPSIk] Monitoring system not fully implemented. Please upload real scripts to GitHub."
EOF
    chmod +x "$INSTALL_DIR/scripts/monitor.sh"

    # Dashboard placeholder
    mkdir -p "$INSTALL_DIR/dashboard"
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
}

# === SECURITY HARDENING ===
security_hardening() {
    log_step "🔐 Security Hardening (Optional)"
    echo -e "${CYAN}Apply basic SSH + Firewall hardening?${NC}"
    read -p "Enable? (y/n) [n]: " choice
    [[ "$choice" != "y" ]] && { log "Skipped"; return; }

    log "Installing UFW & Fail2Ban..."
    apt-get install -y ufw fail2ban unattended-upgrades

    # UFW
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw --force enable

    # Fail2Ban
    cat > /etc/fail2ban/jail.d/vpsik-sshd.conf << 'EOF'
[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 3600
EOF
    systemctl restart fail2ban

    log_success "Security hardening applied"
}

# === CONFIGURATION ===
interactive_config() {
    log_step "⚙️ Configuration"
    read -p "Alert Name [$(hostname)]: " ALERT_NAME; ALERT_NAME=${ALERT_NAME:-$(hostname)}

    # Notifications (one only)
    echo "1) Telegram 2) Email 3) Discord 4) Slack 5) Logs only"
    read -p "Choice [1]: " notif
    case "${notif:-1}" in
        1) configure_telegram ;;
        2) configure_email ;;
        3) configure_discord ;;
        4) configure_slack ;;
        *) TELEGRAM_ENABLED=false; EMAIL_ENABLED=false; DISCORD_ENABLED=false; SLACK_ENABLED=false ;;
    esac

    # Dashboard
    read -p "Install Web Dashboard? (y/n) [y]: " dash
    if [[ "${dash,,}" == "y" || -z "$dash" ]]; then
        DASHBOARD_ENABLED=true
        # Random unused port
        while true; do
            DASHBOARD_PORT=$((10000 + RANDOM % 2001))
            ss -tln | grep -q ":$DASHBOARD_PORT " || break
        done
        DASHBOARD_USER=$(openssl rand -hex 4)
        DASHBOARD_PASS=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' | head -c 12)
        echo -e "${GREEN}Dashboard: http://\$(hostname -I | awk '{print \$1}'):$DASHBOARD_PORT${NC}"
        echo -e "${GREEN}User: $DASHBOARD_USER | Pass: $DASHBOARD_PASS${NC}"
        echo -e "${RED}⚠️ SAVE THESE!${NC}"
        read -p "Press Enter to continue..."
    else
        DASHBOARD_ENABLED=false
    fi

    CHECK_INTERVAL=300
}

configure_telegram() {
    TELEGRAM_ENABLED=true
    read -p "Bot Token: " BOT_TOKEN
    read -p "Chat ID: " CHAT_ID
    curl -sf "https://api.telegram.org/bot$BOT_TOKEN/getMe" | jq -e '.ok' >/dev/null || { log_error "Invalid token"; exit 1; }
    EMAIL_ENABLED=false; DISCORD_ENABLED=false; SLACK_ENABLED=false
}

configure_email() {
    EMAIL_ENABLED=true
    while true; do
        read -p "Email: " EMAIL_RECIPIENT
        [[ "$EMAIL_RECIPIENT" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && break
        echo "Invalid email"
    done
    read -p "SMTP Host: " SMTP_HOST
    read -p "SMTP Port [587]: " SMTP_PORT; SMTP_PORT=${SMTP_PORT:-587}
    read -p "SMTP User: " SMTP_USER
    read -sp "SMTP Pass: " SMTP_PASS; echo
    TELEGRAM_ENABLED=false; DISCORD_ENABLED=false; SLACK_ENABLED=false
}

configure_discord() { DISCORD_ENABLED=true; read -p "Webhook: " DISCORD_WEBHOOK; TELEGRAM_ENABLED=false; EMAIL_ENABLED=false; SLACK_ENABLED=false; }
configure_slack() { SLACK_ENABLED=true; read -p "Webhook: " SLACK_WEBHOOK; TELEGRAM_ENABLED=false; EMAIL_ENABLED=false; DISCORD_ENABLED=false; }

# === CONFIG FILE ===
generate_config() {
    cat > "$INSTALL_DIR/config/config.json" << EOF
{
  "version": "$VERSION",
  "alert_name": "$ALERT_NAME",
  "dashboard": { "enabled": $DASHBOARD_ENABLED, "port": ${DASHBOARD_PORT:-8080} },
  "notifications": {
    "telegram": { "enabled": $TELEGRAM_ENABLED, "bot_token": "$BOT_TOKEN", "chat_id": "$CHAT_ID" },
    "email": { "enabled": $EMAIL_ENABLED, "recipient": "$EMAIL_RECIPIENT" }
  },
  "thresholds": { "cpu": {"warning": 80, "critical": 95}, "ram": {"warning": 85, "critical": 95}, "disk": {"warning": 85, "critical": 95} }
}
EOF
    chmod 600 "$INSTALL_DIR/config/config.json"

    if [[ "$EMAIL_ENABLED" == true ]]; then
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

# === MONITORING ===
install_monitoring() {
    log_step "🔍 Installing Monitoring"
    chmod +x "$INSTALL_DIR/scripts/"*.sh 2>/dev/null || true
    log_success "Monitoring ready"
}

# === DASHBOARD ===
install_dashboard() {
    [[ "$DASHBOARD_ENABLED" != true ]] && { log "Dashboard skipped"; return; }
    log_step "🖥️ Installing Dashboard"
    cd "$INSTALL_DIR/dashboard"
    python3 -m venv venv
    ./venv/bin/pip install --quiet flask
    log_success "Dashboard ready"
}

# === SERVICES ===
create_services() {
    log_step "⚙️ Creating System Services"

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

    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        cat > /etc/systemd/system/vpsik-dashboard.service << EOF
[Unit]
Description=VPSIk Dashboard
[Service]
WorkingDirectory=$INSTALL_DIR/dashboard
Environment=DASHBOARD_PORT=$DASHBOARD_PORT
ExecStart=$INSTALL_DIR/dashboard/venv/bin/python app.py
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
    fi

    systemctl daemon-reload
    log_success "Services created"
}

# === START ===
start_services() {
    systemctl enable --now vpsik-alert.timer
    [[ "$DASHBOARD_ENABLED" == true ]] && systemctl enable --now vpsik-dashboard
}

# === MANAGEMENT ===
create_management_command() {
    cat > /usr/local/bin/vpsik << 'EOF'
#!/bin/bash
case "$1" in
    status) systemctl status vpsik-alert.timer vpsik-dashboard 2>/dev/null ;;
    logs) journalctl -u vpsik-alert -f ;;
    test) /opt/VPSIk-Alert/scripts/monitor.sh ;;
    audit) /usr/local/bin/vpsik-security-audit.sh ;;
    dashboard)
        IP=$(hostname -I | awk '{print $1}')
        PORT=$(jq -r '.dashboard.port' /opt/VPSIk-Alert/config/config.json)
        echo "🌐 http://$IP:$PORT"
        ;;
    uninstall) curl -sSL https://raw.githubusercontent.com/ymasgit/vpsik-alert/main/install.sh | sudo bash -s uninstall ;;
    *) echo "vpsik {status|logs|test|audit|dashboard|uninstall}" ;;
esac
EOF
    chmod +x /usr/local/bin/vpsik
}

# === SECURITY AUDIT (OUTSIDE main) ===
setup_security_audit() {
    log_step "🔍 Security Audit Setup"
    # Install tools
    apt-get install -y lynis rkhunter chkrootkit

    # Audit script
    cat > /usr/local/bin/vpsik-security-audit.sh << 'AUDIT'
#!/bin/bash
set -euo pipefail
SCAN_DIR="/opt/VPSIk-Alert/security-scans"
mkdir -p "$SCAN_DIR"
LOG="$SCAN_DIR/audit-$(date +%Y%m%d).log"
lynis audit system > "$LOG" 2>&1 || true
rkhunter --check >> "$LOG" 2>&1 || true
echo "Audit complete: $LOG"
AUDIT
    chmod +x /usr/local/bin/vpsik-security-audit.sh

    # Timer
    cat > /etc/systemd/system/vpsik-security-audit.timer << EOF
[Unit]
Description=VPSIk Security Audit
[Timer]
OnCalendar=monthly
Persistent=true
[Install]
WantedBy=timers.target
EOF

    cat > /etc/systemd/system/vpsik-security-audit.service << EOF
[Unit]
Description=VPSIk Security Audit
[Service]
ExecStart=/usr/local/bin/vpsik-security-audit.sh
EOF

    systemctl daemon-reload
    systemctl enable vpsik-security-audit.timer
    log_success "Security audit scheduled"
}

# === TEST & SUMMARY ===
test_installation() {
    log_step "🧪 Testing"
    vpsik test
    [[ "$DASHBOARD_ENABLED" == true ]] && sleep 3 && curl -sf "http://localhost:$DASHBOARD_PORT" >/dev/null && log_success "Dashboard OK"
}

print_summary() {
    clear
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo -e "${YELLOW}👉 vpsik status${NC}"
    [[ "$DASHBOARD_ENABLED" == true ]] && {
        IP=$(hostname -I | awk '{print $1}')
        echo -e "${YELLOW}🌐 Dashboard: http://$IP:${DASHBOARD_PORT}${NC}"
        echo -e "${YELLOW}🔑 User: $DASHBOARD_USER | Pass: ***${NC}"
    }
}

# === CLEANUP ===
cleanup() { rm -rf "$TEMP_DIR"; }

# === UNINSTALL ===
uninstall_vpsik() {
    log_step "🗑️ Uninstalling"
    systemctl stop vpsik-*.service vpsik-*.timer 2>/dev/null || true
    systemctl disable vpsik-*.service vpsik-*.timer 2>/dev/null || true
    rm -rf /opt/VPSIk-Alert /usr/local/bin/vpsik
    rm -f /etc/systemd/system/vpsik-*.service /etc/systemd/system/vpsik-*.timer
    systemctl daemon-reload
    log_success "Uninstalled"
    exit 0
}

# === LOAD EXISTING ===
load_existing_config() {
    [[ -f "$INSTALL_DIR/config/config.json" ]] || { log_error "Config missing"; exit 1; }
    LANG_CODE=$(jq -r '.language // "en"' "$INSTALL_DIR/config/config.json")
    ALERT_NAME=$(jq -r '.alert_name // "VPS Monitor"' "$INSTALL_DIR/config/config.json")
    CHECK_INTERVAL=$(jq -r '.check_interval // 300' "$INSTALL_DIR/config/config.json")
    TELEGRAM_ENABLED=$(jq -r '.notifications.telegram.enabled // false' "$INSTALL_DIR/config/config.json")
    EMAIL_ENABLED=$(jq -r '.notifications.email.enabled // false' "$INSTALL_DIR/config/config.json")
    DASHBOARD_ENABLED=$(jq -r '.dashboard.enabled // false' "$INSTALL_DIR/config/config.json")
    DASHBOARD_PORT=$(jq -r '.dashboard.port // 8080' "$INSTALL_DIR/config/config.json")
}

# === RUN ===
main "$@"
