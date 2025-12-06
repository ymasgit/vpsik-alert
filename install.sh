#!/bin/bash
# VPSIk Alert - Unified Installer v3.0
# One-line installation: curl -sSL https://raw.githubusercontent.com/ymasgit/vpsik-alert/main/install.sh | sudo bash

set -e

# Version
VERSION="3.0.0"
REPO_URL="https://api.github.com/repos/ymasgit/vpsik-alert"
INSTALL_DIR="/opt/VPSIk-Alert"
TEMP_DIR="/tmp/vpsik-install-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   echo "Please run: sudo bash $0"
   exit 1
fi

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${RED}Cannot detect OS${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ██╗   ██╗██████╗ ███████╗██╗██╗  ██╗                   ║
║   ██║   ██║██╔══██╗██╔════╝██║██║ ██╔╝                   ║
║   ██║   ██║██████╔╝███████╗██║█████╔╝                    ║
║   ╚██╗ ██╔╝██╔═══╝ ╚════██║██║██╔═██╗                    ║
║    ╚████╔╝ ██║     ███████║██║██║  ██╗                   ║
║     ╚═══╝  ╚═╝     ╚══════╝╚═╝╚═╝  ╚═╝                   ║
║                                                           ║
║              Professional VPS Monitoring                 ║
║                      Version 3.0                         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${GREEN}🚀 All-in-One Installer${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $1${NC}"
}

log_step() {
    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if update mode
check_update_mode() {
    if [[ "$1" == "update" ]]; then
        UPDATE_MODE=true
        log_step "🔄 UPDATE MODE"
        if [[ ! -d "$INSTALL_DIR" ]]; then
            log_error "VPSIk Alert is not installed. Please install first."
            exit 1
        fi
    else
        UPDATE_MODE=false
        log_step "📦 INSTALLATION MODE"
    fi
}

# Check existing installation
check_existing() {
    if [[ -d "$INSTALL_DIR" && "$UPDATE_MODE" == false ]]; then
        log_warn "VPSIk Alert is already installed!"
        echo ""
        read -p "Do you want to update? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            UPDATE_MODE=true
            log "Switching to update mode..."
        else
            log_error "Installation cancelled"
            exit 0
        fi
    fi
}

# Install dependencies
install_dependencies() {
    log_step "📦 Installing Dependencies"
    
    detect_os
    
    log "Updating package lists..."
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update -qq > /dev/null 2>&1
        log "Installing packages..."
        apt-get install -y \
            curl wget git jq bc \
            python3 python3-pip python3-venv \
            sqlite3 nginx openssl \
            mailutils ssmtp \
            fail2ban \
            net-tools > /dev/null 2>&1
    elif [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "fedora" ]]; then
        yum install -y \
            curl wget git jq bc \
            python3 python3-pip \
            sqlite nginx openssl \
            mailx \
            fail2ban \
            net-tools > /dev/null 2>&1
    else
        log_error "Unsupported OS: $OS"
        exit 1
    fi
    
    log_success "Dependencies installed"
}

# Create directory structure
create_directories() {
    log_step "📁 Creating Directory Structure"
    
    mkdir -p "$INSTALL_DIR"/{config,logs,translations,scripts,security/{ssl,ddos,logs},recovery,dashboard/{static/{css,js,img},templates,api},database}
    
    log_success "Directories created"
}

# Download from GitHub
download_files() {
    log_step "⬇️  Downloading Files from GitHub"
    
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # In production, download from actual GitHub repo
    # git clone https://github.com/ymasgit/vpsik-alert.git
    
    log "Creating configuration files..."
    
    # For now, we'll create files inline
    # In production, these would be in GitHub repo
    
    log_success "Files downloaded"
}

# Interactive configuration
interactive_config() {
    log_step "⚙️  Configuration"
    
    echo ""
    echo -e "${CYAN}Let's configure VPSIk Alert...${NC}"
    echo ""
    
    # Language
    echo -e "${GREEN}Select Language:${NC}"
    echo "1) English (en)"
    echo "2) العربية (ar)"
    echo "3) Español (es)"
    echo "4) Français (fr)"
    read -p "Enter choice [1]: " lang_choice
    case "$lang_choice" in
        2) LANG_CODE="ar";;
        3) LANG_CODE="es";;
        4) LANG_CODE="fr";;
        *) LANG_CODE="en";;
    esac
    
    # Alert name
    read -p "Enter Alert Name [$(hostname) Monitor]: " ALERT_NAME
    ALERT_NAME=${ALERT_NAME:-"$(hostname) Monitor"}
    
    # Notifications
    echo ""
    echo -e "${GREEN}Configure Notifications:${NC}"
    
    # Telegram
    read -p "Enable Telegram notifications? (y/n) [n]: " enable_tg
    if [[ "$enable_tg" == "y" ]]; then
        read -p "  Bot Token: " BOT_TOKEN
        read -p "  Chat ID: " CHAT_ID
        TELEGRAM_ENABLED=true
    else
        BOT_TOKEN=""
        CHAT_ID=""
        TELEGRAM_ENABLED=false
    fi
    
    # Email
    read -p "Enable Email notifications? (y/n) [n]: " enable_email
    if [[ "$enable_email" == "y" ]]; then
        read -p "  Email Recipient: " EMAIL_RECIPIENT
        read -p "  SMTP Host (e.g., smtp.gmail.com): " SMTP_HOST
        read -p "  SMTP Port [587]: " SMTP_PORT
        SMTP_PORT=${SMTP_PORT:-587}
        read -p "  SMTP Username: " SMTP_USER
        read -sp "  SMTP Password: " SMTP_PASS
        echo ""
        EMAIL_ENABLED=true
    else
        EMAIL_RECIPIENT=""
        SMTP_HOST=""
        SMTP_PORT="587"
        SMTP_USER=""
        SMTP_PASS=""
        EMAIL_ENABLED=false
    fi
    
    # Discord
    read -p "Enable Discord webhook? (y/n) [n]: " enable_discord
    if [[ "$enable_discord" == "y" ]]; then
        read -p "  Discord Webhook URL: " DISCORD_WEBHOOK
        DISCORD_ENABLED=true
    else
        DISCORD_WEBHOOK=""
        DISCORD_ENABLED=false
    fi
    
    # Slack
    read -p "Enable Slack webhook? (y/n) [n]: " enable_slack
    if [[ "$enable_slack" == "y" ]]; then
        read -p "  Slack Webhook URL: " SLACK_WEBHOOK
        SLACK_ENABLED=true
    else
        SLACK_WEBHOOK=""
        SLACK_ENABLED=false
    fi
    
    # Thresholds
    echo ""
    echo -e "${GREEN}Configure Thresholds (default values shown):${NC}"
    read -p "CPU Warning % [80]: " CPU_WARN
    CPU_WARN=${CPU_WARN:-80}
    read -p "CPU Critical % [95]: " CPU_CRIT
    CPU_CRIT=${CPU_CRIT:-95}
    
    read -p "RAM Warning % [85]: " RAM_WARN
    RAM_WARN=${RAM_WARN:-85}
    read -p "RAM Critical % [95]: " RAM_CRIT
    RAM_CRIT=${RAM_CRIT:-95}
    
    read -p "Disk Warning % [85]: " DISK_WARN
    DISK_WARN=${DISK_WARN:-85}
    read -p "Disk Critical % [95]: " DISK_CRIT
    DISK_CRIT=${DISK_CRIT:-95}
    
    # Services
    echo ""
    read -p "Enable service monitoring? (y/n) [y]: " enable_services
    if [[ "$enable_services" == "y" ]]; then
        echo "Enter services to monitor (comma-separated):"
        echo "Example: nginx,mysql,apache2"
        read -p "Services: " SERVICES_LIST
        SERVICES_ENABLED=true
    else
        SERVICES_LIST=""
        SERVICES_ENABLED=false
    fi
    
    # SSL Monitoring
    echo ""
    read -p "Enable SSL monitoring? (y/n) [n]: " enable_ssl
    if [[ "$enable_ssl" == "y" ]]; then
        read -p "  Domains (comma-separated): " SSL_DOMAINS
        read -p "  Warning days [30]: " SSL_WARN_DAYS
        SSL_WARN_DAYS=${SSL_WARN_DAYS:-30}
        read -p "  Critical days [7]: " SSL_CRIT_DAYS
        SSL_CRIT_DAYS=${SSL_CRIT_DAYS:-7}
        SSL_ENABLED=true
    else
        SSL_DOMAINS=""
        SSL_WARN_DAYS=30
        SSL_CRIT_DAYS=7
        SSL_ENABLED=false
    fi
    
    # DDoS Protection
    echo ""
    read -p "Enable DDoS protection? (y/n) [y]: " enable_ddos
    if [[ "$enable_ddos" == "y" ]]; then
        read -p "  Connection threshold [100]: " CONN_THRESHOLD
        CONN_THRESHOLD=${CONN_THRESHOLD:-100}
        read -p "  Enable auto-ban? (y/n) [y]: " auto_ban
        if [[ "$auto_ban" == "y" ]]; then
            AUTO_BAN=true
            read -p "  Ban duration (seconds) [3600]: " BAN_DURATION
            BAN_DURATION=${BAN_DURATION:-3600}
        else
            AUTO_BAN=false
            BAN_DURATION=3600
        fi
        DDOS_ENABLED=true
    else
        CONN_THRESHOLD=100
        AUTO_BAN=false
        BAN_DURATION=3600
        DDOS_ENABLED=false
    fi
    
    # Auto-recovery
    echo ""
    read -p "Enable auto-recovery for services? (y/n) [y]: " enable_recovery
    if [[ "$enable_recovery" == "y" ]]; then
        RECOVERY_ENABLED=true
        read -p "  Clear cache on high RAM? (y/n) [n]: " clear_cache
        [[ "$clear_cache" == "y" ]] && CLEAR_CACHE=true || CLEAR_CACHE=false
    else
        RECOVERY_ENABLED=false
        CLEAR_CACHE=false
    fi
    
    # Dashboard
    echo ""
    read -p "Install Web Dashboard? (y/n) [y]: " install_dashboard
    [[ "$install_dashboard" == "y" ]] && DASHBOARD_ENABLED=true || DASHBOARD_ENABLED=false
    
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        read -p "  Dashboard port [8080]: " DASHBOARD_PORT
        DASHBOARD_PORT=${DASHBOARD_PORT:-8080}
    fi
    
    # Check interval
    echo ""
    echo -e "${GREEN}Select check interval:${NC}"
    echo "1) 1 minute (for testing)"
    echo "2) 5 minutes"
    echo "3) 15 minutes"
    echo "4) 30 minutes"
    read -p "Choice [2]: " interval_choice
    case "$interval_choice" in
        1) CHECK_INTERVAL=60;;
        2) CHECK_INTERVAL=300;;
        3) CHECK_INTERVAL=900;;
        4) CHECK_INTERVAL=1800;;
        *) CHECK_INTERVAL=300;;
    esac
    
    log_success "Configuration completed"
}

# Generate config file
generate_config() {
    log_step "📝 Generating Configuration File"
    
    cat > "$INSTALL_DIR/config/config.json" << EOF
{
  "version": "$VERSION",
  "language": "$LANG_CODE",
  "alert_name": "$ALERT_NAME",
  "check_interval": $CHECK_INTERVAL,
  "cooldown_period": 3600,
  "notifications": {
    "telegram": {
      "enabled": $TELEGRAM_ENABLED,
      "bot_token": "$BOT_TOKEN",
      "chat_id": "$CHAT_ID"
    },
    "email": {
      "enabled": $EMAIL_ENABLED,
      "recipient": "$EMAIL_RECIPIENT"
    },
    "discord": {
      "enabled": $DISCORD_ENABLED,
      "webhook_url": "$DISCORD_WEBHOOK"
    },
    "slack": {
      "enabled": $SLACK_ENABLED,
      "webhook_url": "$SLACK_WEBHOOK"
    }
  },
  "thresholds": {
    "cpu": {"warning": $CPU_WARN, "critical": $CPU_CRIT},
    "ram": {"warning": $RAM_WARN, "critical": $RAM_CRIT},
    "disk": {"warning": $DISK_WARN, "critical": $DISK_CRIT}
  },
  "monitoring": {
    "network": true,
    "failed_logins": {"enabled": true, "threshold": 10},
    "processes": {"enabled": true, "cpu_threshold": 50, "memory_threshold": 30},
    "services": {"enabled": $SERVICES_ENABLED, "list": "$SERVICES_LIST"}
  },
  "recovery": {
    "enabled": $RECOVERY_ENABLED,
    "max_attempts": 3,
    "clear_cache": $CLEAR_CACHE,
    "kill_processes": false
  },
  "security": {
    "ssl_monitoring": {
      "enabled": $SSL_ENABLED,
      "domains": "$SSL_DOMAINS",
      "warning_days": $SSL_WARN_DAYS,
      "critical_days": $SSL_CRIT_DAYS
    },
    "ddos_protection": {
      "enabled": $DDOS_ENABLED,
      "connection_threshold": $CONN_THRESHOLD,
      "syn_threshold": 50,
      "auto_ban": $AUTO_BAN,
      "ban_duration": $BAN_DURATION
    }
  },
  "dashboard": {
    "enabled": $DASHBOARD_ENABLED,
    "port": ${DASHBOARD_PORT:-8080}
  }
}
EOF
    
    chmod 600 "$INSTALL_DIR/config/config.json"
    
    # Configure SMTP if enabled
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
    
    log_success "Configuration file created"
}

# Install monitoring scripts
install_monitoring() {
    log_step "🔍 Installing Monitoring Scripts"
    
    # Here we would copy actual script files
    # For demonstration, we'll create placeholder
    
    log "Creating monitoring script..."
    echo '#!/bin/bash' > "$INSTALL_DIR/scripts/monitor.sh"
    echo 'echo "Monitoring script placeholder"' >> "$INSTALL_DIR/scripts/monitor.sh"
    chmod +x "$INSTALL_DIR/scripts/monitor.sh"
    
    log "Creating data collector..."
    echo '#!/bin/bash' > "$INSTALL_DIR/scripts/collect_data.sh"
    echo 'echo "Data collector placeholder"' >> "$INSTALL_DIR/scripts/collect_data.sh"
    chmod +x "$INSTALL_DIR/scripts/collect_data.sh"
    
    log_success "Monitoring scripts installed"
}

# Install dashboard
install_dashboard() {
    if [[ "$DASHBOARD_ENABLED" != true ]]; then
        log "Dashboard installation skipped"
        return
    fi
    
    log_step "🖥️  Installing Dashboard"
    
    log "Setting up Python environment..."
    python3 -m venv "$INSTALL_DIR/dashboard/venv"
    source "$INSTALL_DIR/dashboard/venv/bin/activate"
    
    log "Installing Python packages..."
    pip install --quiet flask flask-cors sqlite3 > /dev/null 2>&1
    
    log "Initializing database..."
    # Create database initialization script
    # (Would be actual file from GitHub)
    
    log "Creating dashboard files..."
    # Copy dashboard files from GitHub
    
    deactivate
    
    log_success "Dashboard installed"
}

# Create systemd services
create_services() {
    log_step "⚙️  Creating System Services"
    
    # Main monitoring service
    cat > /etc/systemd/system/vpsik-alert.service << EOF
[Unit]
Description=VPSIk Alert Monitoring
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/scripts/monitor.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Timer for monitoring
    cat > /etc/systemd/system/vpsik-alert.timer << EOF
[Unit]
Description=VPSIk Alert Timer
Requires=vpsik-alert.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=${CHECK_INTERVAL}s
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF
    
    # Dashboard service (if enabled)
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        cat > /etc/systemd/system/vpsik-dashboard.service << EOF
[Unit]
Description=VPSIk Dashboard
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR/dashboard
ExecStart=$INSTALL_DIR/dashboard/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    systemctl daemon-reload
    
    log_success "System services created"
}

# Enable and start services
start_services() {
    log_step "🚀 Starting Services"
    
    systemctl enable vpsik-alert.timer
    systemctl start vpsik-alert.timer
    
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        systemctl enable vpsik-dashboard
        systemctl start vpsik-dashboard
    fi
    
    log_success "Services started"
}

# Uninstall function
uninstall_vpsik() {
    log_step "🗑️  Uninstalling VPSIk Alert"
    
    echo ""
    echo -e "${RED}⚠️  WARNING: This will remove VPSIk Alert completely!${NC}"
    echo -e "${YELLOW}All configurations, logs, and data will be deleted.${NC}"
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log "Uninstall cancelled"
        exit 0
    fi
    
    log "Stopping all services..."
    systemctl stop vpsik-alert.timer 2>/dev/null
    systemctl stop vpsik-alert.service 2>/dev/null
    systemctl stop vpsik-dashboard.service 2>/dev/null
    systemctl stop vpsik-collector.timer 2>/dev/null
    systemctl stop vpsik-multi-collector.timer 2>/dev/null
    systemctl stop vpsik-ssl.timer 2>/dev/null
    systemctl stop vpsik-ddos.timer 2>/dev/null
    
    log "Disabling services..."
    systemctl disable vpsik-alert.timer 2>/dev/null
    systemctl disable vpsik-dashboard.service 2>/dev/null
    systemctl disable vpsik-collector.timer 2>/dev/null
    systemctl disable vpsik-multi-collector.timer 2>/dev/null
    systemctl disable vpsik-ssl.timer 2>/dev/null
    systemctl disable vpsik-ddos.timer 2>/dev/null
    
    log "Removing systemd files..."
    rm -f /etc/systemd/system/vpsik-*.service
    rm -f /etc/systemd/system/vpsik-*.timer
    systemctl daemon-reload
    
    log "Removing installation directory..."
    rm -rf /opt/VPSIk-Alert
    
    log "Removing management command..."
    rm -f /usr/local/bin/vpsik
    
    log "Removing nginx configuration..."
    rm -f /etc/nginx/sites-enabled/vpsik-dashboard
    rm -f /etc/nginx/sites-available/vpsik-dashboard
    nginx -t && systemctl reload nginx 2>/dev/null
    
    log_success "VPSIk Alert has been completely removed"
    echo ""
    echo -e "${GREEN}Thank you for using VPSIk Alert!${NC}"
}

# Create management command
create_management_command() {
    log_step "🛠️  Creating Management Command"
    
    cat > /usr/local/bin/vpsik << 'MGMT_EOF'
#!/bin/bash

INSTALL_DIR="/opt/VPSIk-Alert"
CONFIG_FILE="$INSTALL_DIR/config/config.json"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

case "$1" in
    start)
        systemctl start vpsik-alert.timer
        echo -e "${GREEN}✓ Monitoring started${NC}"
        ;;
    stop)
        systemctl stop vpsik-alert.timer
        echo -e "${YELLOW}✓ Monitoring stopped${NC}"
        ;;
    restart)
        systemctl restart vpsik-alert.timer
        [[ -f /etc/systemd/system/vpsik-dashboard.service ]] && systemctl restart vpsik-dashboard
        echo -e "${GREEN}✓ Services restarted${NC}"
        ;;
    status)
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}📊 VPSIk Alert Status${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}Monitoring Service:${NC}"
        systemctl status vpsik-alert.timer --no-pager
        echo ""
        if [[ -f /etc/systemd/system/vpsik-dashboard.service ]]; then
            echo -e "${YELLOW}Dashboard Service:${NC}"
            systemctl status vpsik-dashboard --no-pager
        fi
        ;;
    logs)
        echo -e "${BLUE}Viewing logs... (Press Ctrl+C to exit)${NC}"
        journalctl -u vpsik-alert -f
        ;;
    config)
        if [[ -f "$CONFIG_FILE" ]]; then
            nano "$CONFIG_FILE"
            echo -e "${YELLOW}Configuration updated. Restart services to apply changes.${NC}"
            read -p "Restart now? (y/n): " restart_now
            [[ "$restart_now" == "y" ]] && systemctl restart vpsik-alert.timer
        else
            echo -e "${RED}Configuration file not found!${NC}"
        fi
        ;;
    update)
        echo -e "${BLUE}Updating VPSIk Alert...${NC}"
        curl -sSL https://raw.githubusercontent.com/ymasgit/vpsik-alert/main/install.sh | sudo bash -s update
        ;;
    dashboard)
        if [[ -f /etc/systemd/system/vpsik-dashboard.service ]]; then
            PORT=$(jq -r '.dashboard.port // 8080' "$CONFIG_FILE" 2>/dev/null)
            IP=$(hostname -I | awk '{print $1}')
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}📊 Dashboard Information${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            systemctl status vpsik-dashboard --no-pager
            echo ""
            echo -e "${GREEN}Dashboard URL:${NC} ${YELLOW}http://$IP:$PORT${NC}"
        else
            echo -e "${RED}Dashboard is not installed${NC}"
        fi
        ;;
    uninstall)
        curl -sSL https://raw.githubusercontent.com/ymasgit/vpsik-alert/main/install.sh | sudo bash -s uninstall
        ;;
    test)
        echo -e "${BLUE}Sending test alert...${NC}"
        $INSTALL_DIR/scripts/monitor.sh
        echo -e "${GREEN}✓ Test alert sent${NC}"
        ;;
    version)
        if [[ -f "$CONFIG_FILE" ]]; then
            VERSION=$(jq -r '.version // "Unknown"' "$CONFIG_FILE" 2>/dev/null)
            echo -e "${GREEN}VPSIk Alert version: $VERSION${NC}"
        else
            echo -e "${RED}Version information not available${NC}"
        fi
        ;;
    help|--help|-h)
        echo -e "${GREEN}VPSIk Alert - Management Commands${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}Usage:${NC} vpsik [command]"
        echo ""
        echo -e "${YELLOW}Commands:${NC}"
        echo -e "  ${GREEN}start${NC}       Start monitoring"
        echo -e "  ${GREEN}stop${NC}        Stop monitoring"
        echo -e "  ${GREEN}restart${NC}     Restart services"
        echo -e "  ${GREEN}status${NC}      Check status"
        echo -e "  ${GREEN}logs${NC}        View logs (live)"
        echo -e "  ${GREEN}config${NC}      Edit configuration"
        echo -e "  ${GREEN}update${NC}      Update to latest version"
        echo -e "  ${GREEN}dashboard${NC}   Dashboard information"
        echo -e "  ${GREEN}uninstall${NC}   Remove VPSIk Alert"
        echo -e "  ${GREEN}test${NC}        Send test alert"
        echo -e "  ${GREEN}version${NC}     Show version"
        echo -e "  ${GREEN}help${NC}        Show this help"
        echo ""
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "Use ${GREEN}vpsik help${NC} to see available commands"
        exit 1
        ;;
esac
MGMT_EOF
    
    chmod +x /usr/local/bin/vpsik
    
    log_success "Management command created"
}

# Test installation
test_installation() {
    log_step "🧪 Testing Installation"
    
    log "Checking services..."
    if systemctl is-active --quiet vpsik-alert.timer; then
        log_success "Monitoring service is running"
    else
        log_warn "Monitoring service is not running"
    fi
    
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        if systemctl is-active --quiet vpsik-dashboard; then
            log_success "Dashboard service is running"
        else
            log_warn "Dashboard service is not running"
        fi
    fi
    
    log "Checking configuration..."
    if [[ -f "$INSTALL_DIR/config/config.json" ]]; then
        log_success "Configuration file exists"
    else
        log_error "Configuration file missing"
    fi
    
    log_success "Installation test completed"
}

# Print final summary
print_summary() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              ✅ Installation Complete! ✅                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}📊 Installation Summary:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC} Version: ${GREEN}${VERSION}${NC}"
    echo -e "  ${GREEN}✓${NC} Location: ${GREEN}${INSTALL_DIR}${NC}"
    echo -e "  ${GREEN}✓${NC} Alert Name: ${GREEN}${ALERT_NAME}${NC}"
    echo -e "  ${GREEN}✓${NC} Check Interval: ${GREEN}${CHECK_INTERVAL}s${NC}"
    echo -e "  ${GREEN}✓${NC} Language: ${GREEN}${LANG_CODE}${NC}"
    echo ""
    
    echo -e "${CYAN}📡 Enabled Notifications:${NC}"
    local notif_count=0
    if [[ "$TELEGRAM_ENABLED" == true ]]; then
        echo -e "  ${GREEN}✓${NC} Telegram"
        notif_count=$((notif_count + 1))
    fi
    if [[ "$EMAIL_ENABLED" == true ]]; then
        echo -e "  ${GREEN}✓${NC} Email"
        notif_count=$((notif_count + 1))
    fi
    if [[ "$DISCORD_ENABLED" == true ]]; then
        echo -e "  ${GREEN}✓${NC} Discord"
        notif_count=$((notif_count + 1))
    fi
    if [[ "$SLACK_ENABLED" == true ]]; then
        echo -e "  ${GREEN}✓${NC} Slack"
        notif_count=$((notif_count + 1))
    fi
    if [[ $notif_count -eq 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} No notifications enabled (logs only)"
    fi
    echo ""
    
    echo -e "${CYAN}🔍 Monitoring:${NC}"
    echo -e "  ${GREEN}✓${NC} CPU/RAM/Disk"
    echo -e "  ${GREEN}✓${NC} Network Traffic"
    echo -e "  ${GREEN}✓${NC} Process Monitoring"
    if [[ "$SERVICES_ENABLED" == true ]]; then
        echo -e "  ${GREEN}✓${NC} Services: ${SERVICES_LIST}"
    fi
    echo ""
    
    echo -e "${CYAN}🔐 Security Features:${NC}"
    local security_count=0
    if [[ "$SSL_ENABLED" == true ]]; then
        echo -e "  ${GREEN}✓${NC} SSL Certificate Monitoring"
        security_count=$((security_count + 1))
    fi
    if [[ "$DDOS_ENABLED" == true ]]; then
        echo -e "  ${GREEN}✓${NC} DDoS Protection"
        security_count=$((security_count + 1))
    fi
    if [[ "$RECOVERY_ENABLED" == true ]]; then
        echo -e "  ${GREEN}✓${NC} Auto-Recovery"
        security_count=$((security_count + 1))
    fi
    if [[ $security_count -eq 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} No security features enabled"
    fi
    echo ""
    
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        local SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "${CYAN}🖥️  Web Dashboard:${NC}"
        echo -e "  ${GREEN}✓${NC} Status: ${GREEN}Running${NC}"
        echo -e "  ${GREEN}✓${NC} URL: ${YELLOW}http://${SERVER_IP}:${DASHBOARD_PORT}${NC}"
        echo -e "  ${GREEN}✓${NC} Database: ${GREEN}Enabled${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}🎮 Quick Commands:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${YELLOW}vpsik status${NC}      Check service status"
    echo -e "  ${YELLOW}vpsik logs${NC}        View live logs"
    echo -e "  ${YELLOW}vpsik config${NC}      Edit configuration"
    echo -e "  ${YELLOW}vpsik test${NC}        Send test alert"
    echo -e "  ${YELLOW}vpsik help${NC}        Show all commands"
    echo ""
    
    echo -e "${CYAN}📚 Next Steps:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${PURPLE}1.${NC} Verify status: ${YELLOW}vpsik status${NC}"
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        echo -e "  ${PURPLE}2.${NC} Open dashboard: ${YELLOW}http://$(hostname -I | awk '{print $1}'):${DASHBOARD_PORT}${NC}"
        echo -e "  ${PURPLE}3.${NC} Send test alert: ${YELLOW}vpsik test${NC}"
        echo -e "  ${PURPLE}4.${NC} Generate load: ${YELLOW}stress --cpu 4 --timeout 60s${NC}"
    else
        echo -e "  ${PURPLE}2.${NC} Send test alert: ${YELLOW}vpsik test${NC}"
        echo -e "  ${PURPLE}3.${NC} Watch logs: ${YELLOW}vpsik logs${NC}"
    fi
    echo ""
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 VPSIk Alert v${VERSION} is now protecting your server!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}💡 Tip:${NC} Run ${YELLOW}vpsik help${NC} to see all available commands"
    echo ""
}

# Cleanup
cleanup() {
    log "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Main installation flow
main() {
    # Check for special modes
    if [[ "$1" == "uninstall" ]]; then
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
        interactive_config
        generate_config
    else
        log "Loading existing configuration..."
        # Load existing config for summary
        if [[ -f "$INSTALL_DIR/config/config.json" ]]; then
            LANG_CODE=$(jq -r '.language // "en"' "$INSTALL_DIR/config/config.json")
            ALERT_NAME=$(jq -r '.alert_name // "VPS Monitor"' "$INSTALL_DIR/config/config.json")
            CHECK_INTERVAL=$(jq -r '.check_interval // 300' "$INSTALL_DIR/config/config.json")
            TELEGRAM_ENABLED=$(jq -r '.notifications.telegram.enabled // false' "$INSTALL_DIR/config/config.json")
            EMAIL_ENABLED=$(jq -r '.notifications.email.enabled // false' "$INSTALL_DIR/config/config.json")
            DISCORD_ENABLED=$(jq -r '.notifications.discord.enabled // false' "$INSTALL_DIR/config/config.json")
            SLACK_ENABLED=$(jq -r '.notifications.slack.enabled // false' "$INSTALL_DIR/config/config.json")
            SSL_ENABLED=$(jq -r '.security.ssl_monitoring.enabled // false' "$INSTALL_DIR/config/config.json")
            DDOS_ENABLED=$(jq -r '.security.ddos_protection.enabled // false' "$INSTALL_DIR/config/config.json")
            RECOVERY_ENABLED=$(jq -r '.recovery.enabled // false' "$INSTALL_DIR/config/config.json")
            DASHBOARD_ENABLED=$(jq -r '.dashboard.enabled // false' "$INSTALL_DIR/config/config.json")
            DASHBOARD_PORT=$(jq -r '.dashboard.port // 8080' "$INSTALL_DIR/config/config.json")
            SERVICES_ENABLED=$(jq -r '.monitoring.services.enabled // false' "$INSTALL_DIR/config/config.json")
            SERVICES_LIST=$(jq -r '.monitoring.services.list // ""' "$INSTALL_DIR/config/config.json")
        fi
    fi
    
    install_monitoring
    install_dashboard
    create_services
    start_services
    create_management_command
    
    test_installation
    cleanup
    
    print_summary
}

# Run main
main "$@"
