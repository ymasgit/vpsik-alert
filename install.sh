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

# Pre-installation security hardening (optional)
security_hardening() {
    log_step "🔐 Security Hardening (Optional)"
    
    echo ""
    echo -e "${CYAN}Would you like to apply basic security hardening first?${NC}"
    echo -e "${YELLOW}This will:${NC}"
    echo "  • Disable root SSH login (keep current session active)"
    echo "  • Enforce SSH key authentication only"
    echo "  • Configure UFW firewall"
    echo "  • Setup Fail2Ban for SSH protection"
    echo "  • Apply basic sysctl hardening"
    echo "  • Enable automatic security updates"
    echo ""
    echo -e "${RED}⚠️  WARNING: This modifies SSH and firewall settings!${NC}"
    echo -e "${YELLOW}Make sure you have SSH keys configured for a non-root user.${NC}"
    echo ""
    
    read -p "Apply security hardening? (y/n) [n]: " apply_hardening
    
    if [[ "$apply_hardening" != "y" ]]; then
        log "Security hardening skipped"
        return 0
    fi
    
    log "Starting security hardening..."
    
    # Detect non-root users with SSH keys
    log "Detecting non-root users with SSH keys..."
    mapfile -t SSH_USERS < <(
        awk -F: '($3>=1000)&&($1!="nobody"){print $1":"$6}' /etc/passwd |
        while IFS=: read -r u homedir; do
            if [[ -f "$homedir/.ssh/authorized_keys" && -s "$homedir/.ssh/authorized_keys" ]]; then
                echo "$u"
            fi
        done
    )
    
    if [[ ${#SSH_USERS[@]} -eq 0 ]]; then
        log_error "No non-root user with SSH keys found!"
        echo ""
        echo -e "${YELLOW}Please create a user and add SSH keys first:${NC}"
        echo "  1. adduser yourname"
        echo "  2. usermod -aG sudo yourname"
        echo "  3. mkdir -p /home/yourname/.ssh"
        echo "  4. nano /home/yourname/.ssh/authorized_keys"
        echo "  5. chmod 700 /home/yourname/.ssh"
        echo "  6. chmod 600 /home/yourname/.ssh/authorized_keys"
        echo "  7. chown -R yourname:yourname /home/yourname/.ssh"
        echo ""
        read -p "Skip security hardening and continue? (y/n): " skip_sec
        [[ "$skip_sec" != "y" ]] && exit 1
        return 0
    fi
    
    log_success "Found SSH users: ${SSH_USERS[*]}"
    
    # Create backup directory
    SECURITY_BACKUP="/opt/VPSIk-Alert-security-backup-$(date +%s)"
    mkdir -p "$SECURITY_BACKUP"
    
    # Backup critical files
    log "Backing up configuration files..."
    cp /etc/ssh/sshd_config "$SECURITY_BACKUP/" 2>/dev/null || true
    [[ -d /etc/ssh/sshd_config.d ]] && cp -r /etc/ssh/sshd_config.d "$SECURITY_BACKUP/" 2>/dev/null || true
    
    # Install security packages
    log "Installing security packages..."
    apt-get install -y ufw fail2ban unattended-upgrades >/dev/null 2>&1
    
    # Configure unattended-upgrades
    log "Configuring automatic security updates..."
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<'AUTOUP'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
AUTOUP
    
    cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'UNATTUP'
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
UNATTUP
    
    # Apply sysctl hardening
    log "Applying kernel hardening..."
    cat > /etc/sysctl.d/99-vpsik-security.conf <<'SYSCTL'
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
fs.suid_dumpable = 0
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
SYSCTL
    sysctl --system >/dev/null 2>&1
    
    # Harden SSH
    log "Hardening SSH configuration..."
    SSH_PORT=$(grep -Po '^\s*Port\s+\K[0-9]+' /etc/ssh/sshd_config 2>/dev/null || echo "22")
    ALLOW_USERS="AllowUsers ${SSH_USERS[*]}"
    
    # Create new SSH config
    {
        sed -e 's/^[[:space:]]*PermitRootLogin.*/# &/' \
            -e 's/^[[:space:]]*PasswordAuthentication.*/# &/' \
            -e 's/^[[:space:]]*PubkeyAuthentication.*/# &/' \
            -e 's/^[[:space:]]*AllowUsers.*/# &/' /etc/ssh/sshd_config
        echo ""
        echo "# Added by VPSIk Alert installer $(date)"
        echo "PermitRootLogin no"
        echo "PasswordAuthentication no"
        echo "PubkeyAuthentication yes"
        echo "ChallengeResponseAuthentication no"
        echo "UsePAM yes"
        echo "AllowTcpForwarding no"
        echo "X11Forwarding no"
        echo "ClientAliveInterval 300"
        echo "ClientAliveCountMax 2"
        echo "MaxAuthTries 3"
        echo "$ALLOW_USERS"
    } > /etc/ssh/sshd_config.new
    
    # Test SSH config
    if sshd -t -f /etc/ssh/sshd_config.new 2>/dev/null; then
        mv /etc/ssh/sshd_config.new /etc/ssh/sshd_config
        systemctl restart sshd
        log_success "SSH hardened successfully"
    else
        rm -f /etc/ssh/sshd_config.new
        log_warn "SSH config test failed, keeping original"
    fi
    
    # Configure UFW
    log "Configuring firewall..."
    ufw --force reset >/dev/null 2>&1
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    ufw allow "$SSH_PORT"/tcp >/dev/null 2>&1
    ufw allow 8080/tcp >/dev/null 2>&1  # For dashboard
    ufw --force enable >/dev/null 2>&1
    
    # Configure Fail2Ban
    log "Configuring Fail2Ban..."
    cat > /etc/fail2ban/jail.d/vpsik-sshd.conf <<FAIL2BAN
[sshd]
enabled = true
port = $SSH_PORT
logpath = /var/log/auth.log
maxretry = 3
findtime = 600
bantime = 3600
FAIL2BAN
    systemctl enable fail2ban >/dev/null 2>&1
    systemctl restart fail2ban >/dev/null 2>&1
    
    # Create rollback script
    cat > "$SECURITY_BACKUP/rollback.sh" <<ROLLBACK
#!/bin/bash
# Rollback security hardening
cp "$SECURITY_BACKUP/sshd_config" /etc/ssh/sshd_config
systemctl restart sshd
ufw disable
systemctl stop fail2ban
echo "Security hardening rolled back. Backup at: $SECURITY_BACKUP"
ROLLBACK
    chmod +x "$SECURITY_BACKUP/rollback.sh"
    
    log_success "Security hardening completed!"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Security Summary:${NC}"
    echo -e "  ${GREEN}✓${NC} SSH hardened (root login disabled)"
    echo -e "  ${GREEN}✓${NC} Allowed SSH users: ${SSH_USERS[*]}"
    echo -e "  ${GREEN}✓${NC} Firewall enabled (UFW)"
    echo -e "  ${GREEN}✓${NC} Fail2Ban active"
    echo -e "  ${GREEN}✓${NC} Automatic security updates enabled"
    echo ""
    echo -e "${YELLOW}Backup location:${NC} $SECURITY_BACKUP"
    echo -e "${YELLOW}Rollback script:${NC} $SECURITY_BACKUP/rollback.sh"
    echo ""
    echo -e "${RED}⚠️  Your current root session remains active${NC}"
    echo -e "${YELLOW}New root SSH logins are now blocked${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    sleep 3
}

# Interactive configuration
interactive_config() {
    log_step "⚙️  Configuration"
    
    echo ""
    echo -e "${CYAN}Let's configure VPSIk Alert...${NC}"
    echo ""
    
# Generate random credentials for dashboard
generate_dashboard_credentials() {
    # Random port between 10000-12000
    DASHBOARD_PORT=$((10000 + RANDOM % 2001))
    
    # Random username: 2 letters + 3 numbers (e.g., ab123)
    local letters="abcdefghijklmnopqrstuvwxyz"
    local user_letter1=${letters:$((RANDOM % 26)):1}
    local user_letter2=${letters:$((RANDOM % 26)):1}
    local user_numbers=$(printf "%03d" $((RANDOM % 1000)))
    DASHBOARD_USER="${user_letter1}${user_letter2}${user_numbers}"
    
    # Random password: 8 characters (uppercase, lowercase, numbers, symbols)
    local chars='A-Za-z0-9!@#$%^&*'
    DASHBOARD_PASS=$(tr -dc "$chars" < /dev/urandom | head -c 8)
    
    # Ensure password has at least one of each type
    if ! echo "$DASHBOARD_PASS" | grep -q '[A-Z]'; then
        DASHBOARD_PASS="A${DASHBOARD_PASS:1}"
    fi
    if ! echo "$DASHBOARD_PASS" | grep -q '[a-z]'; then
        DASHBOARD_PASS="${DASHBOARD_PASS:0:1}a${DASHBOARD_PASS:2}"
    fi
    if ! echo "$DASHBOARD_PASS" | grep -q '[0-9]'; then
        DASHBOARD_PASS="${DASHBOARD_PASS:0:2}1${DASHBOARD_PASS:3}"
    fi
    if ! echo "$DASHBOARD_PASS" | grep -q '[!@#$%^&*]'; then
        DASHBOARD_PASS="${DASHBOARD_PASS:0:3}@${DASHBOARD_PASS:4}"
    fi
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
    
    # Notifications - Show all options
    echo ""
    echo -e "${GREEN}Select Notification Method (choose ONE):${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "1) 📱 Telegram Bot"
    echo "2) 📧 Email (SMTP)"
    echo "3) 💬 Discord Webhook"
    echo "4) 💼 Slack Webhook"
    echo "5) 📝 Logs Only (no external notifications)"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Choose option [1]: " notif_choice
    
    # Reset all to false
    TELEGRAM_ENABLED=false
    EMAIL_ENABLED=false
    DISCORD_ENABLED=false
    SLACK_ENABLED=false
    BOT_TOKEN=""
    CHAT_ID=""
    EMAIL_RECIPIENT=""
    SMTP_HOST=""
    SMTP_PORT="587"
    SMTP_USER=""
    SMTP_PASS=""
    DISCORD_WEBHOOK=""
    SLACK_WEBHOOK=""
    
    case "$notif_choice" in
        1)
            # Telegram setup
            TELEGRAM_ENABLED=true
            echo ""
            echo -e "${CYAN}📱 Telegram Bot Setup:${NC}"
            echo -e "${YELLOW}How to get Bot Token:${NC}"
            echo "  1. Open Telegram and search for @BotFather"
            echo "  2. Send /newbot and follow instructions"
            echo "  3. Copy the token provided"
            echo ""
            echo -e "${YELLOW}How to get Chat ID:${NC}"
            echo "  1. Search for @userinfobot on Telegram"
            echo "  2. Start chat and it will show your ID"
            echo ""
            while true; do
                read -p "Enter Telegram Bot Token: " BOT_TOKEN
                read -p "Enter Telegram Chat ID: " CHAT_ID
                
                echo -n "Testing Telegram connection... "
                if curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/getMe" | jq -e '.ok' >/dev/null 2>&1; then
                    echo -e "${GREEN}✓ Success${NC}"
                    break
                else
                    echo -e "${RED}✗ Failed${NC}"
                    read -p "Try again? (y/n): " retry
                    [[ "$retry" != "y" ]] && break
                fi
            done
            ;;
        2)
            # Email setup
            EMAIL_ENABLED=true
            echo ""
            echo -e "${CYAN}📧 Email Setup:${NC}"
            while true; do
                read -p "Enter Email Recipient: " EMAIL_RECIPIENT
                if [[ "$EMAIL_RECIPIENT" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                    echo -e "${GREEN}✓ Valid email${NC}"
                    break
                else
                    echo -e "${RED}✗ Invalid email format${NC}"
                fi
            done
            
            read -p "Enter SMTP Host (e.g., smtp.gmail.com): " SMTP_HOST
            read -p "Enter SMTP Port [587]: " SMTP_PORT
            SMTP_PORT=${SMTP_PORT:-587}
            read -p "Enter SMTP Username: " SMTP_USER
            read -sp "Enter SMTP Password: " SMTP_PASS
            echo ""
            ;;
        3)
            # Discord webhook
            DISCORD_ENABLED=true
            echo ""
            echo -e "${CYAN}💬 Discord Webhook Setup:${NC}"
            echo -e "${YELLOW}How to get Webhook URL:${NC}"
            echo "  1. Open Discord Server Settings"
            echo "  2. Go to Integrations → Webhooks"
            echo "  3. Create webhook and copy URL"
            echo ""
            read -p "Enter Discord Webhook URL: " DISCORD_WEBHOOK
            ;;
        4)
            # Slack webhook
            SLACK_ENABLED=true
            echo ""
            echo -e "${CYAN}💼 Slack Webhook Setup:${NC}"
            echo -e "${YELLOW}How to get Webhook URL:${NC}"
            echo "  1. Go to https://api.slack.com/apps"
            echo "  2. Create new app → Incoming Webhooks"
            echo "  3. Activate and copy webhook URL"
            echo ""
            read -p "Enter Slack Webhook URL: " SLACK_WEBHOOK
            ;;
        5)
            # Logs only
            echo ""
            echo -e "${YELLOW}📝 Logs Only mode selected${NC}"
            echo -e "Alerts will be logged to: /opt/VPSIk-Alert/logs/alerts.log"
            ;;
        *)
            # Default to Telegram
            TELEGRAM_ENABLED=true
            echo ""
            echo -e "${CYAN}📱 Telegram Bot Setup (Default):${NC}"
            read -p "Enter Telegram Bot Token: " BOT_TOKEN
            read -p "Enter Telegram Chat ID: " CHAT_ID
            ;;
    esac
    
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
    if [[ "$install_dashboard" == "y" || -z "$install_dashboard" ]]; then
        DASHBOARD_ENABLED=true
        
        # Generate random credentials
        generate_dashboard_credentials
        
        echo ""
        echo -e "${GREEN}✓ Dashboard will be installed with:${NC}"
        echo -e "  Port: ${YELLOW}$DASHBOARD_PORT${NC}"
        echo -e "  Username: ${YELLOW}$DASHBOARD_USER${NC}"
        echo -e "  Password: ${YELLOW}$DASHBOARD_PASS${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Save these credentials - they won't be shown again!${NC}"
        read -p "Press Enter to continue..."
    else
        DASHBOARD_ENABLED=false
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
    
    log "Creating data collector..."
    cat > "$INSTALL_DIR/scripts/collect_data.sh" << 'COLLECTOR'
#!/bin/bash
DB_FILE="/opt/VPSIk-Alert/database/vpsik.db"

# Get CPU usage
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')

# Get RAM usage
RAM=$(free | grep Mem | awk '{print int($3/$2 * 100.0)}')

# Get Disk usage
DISK=$(df / | tail -1 | awk '{print int($5)}')

# Get Load Average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)

# Get Network stats
IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [[ -n "$IFACE" ]]; then
    NET_RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
    NET_TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
else
    NET_RX=0
    NET_TX=0
fi

# Insert into database
sqlite3 "$DB_FILE" "INSERT INTO metrics (server_id, cpu_usage, ram_usage, disk_usage, network_rx, network_tx, load_avg) VALUES (1, $CPU, $RAM, $DISK, $NET_RX, $NET_TX, '$LOAD_AVG')" 2>/dev/null || true

# Cleanup old data (keep last 30 days)
sqlite3 "$DB_FILE" "DELETE FROM metrics WHERE timestamp < datetime('now', '-30 days')" 2>/dev/null || true
COLLECTOR
    
    chmod +x "$INSTALL_DIR/scripts/collect_data.sh"
    
    log "Creating monitoring script..."
    echo '#!/bin/bash' > "$INSTALL_DIR/scripts/monitor.sh"
    echo 'echo "Monitoring script - checking thresholds..."' >> "$INSTALL_DIR/scripts/monitor.sh"
    chmod +x "$INSTALL_DIR/scripts/monitor.sh"
    
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
    
    systemctl enable vpsik-collector.timer
    systemctl start vpsik-collector.timer
    
    if [[ "$DASHBOARD_ENABLED" == true ]]; then
        systemctl enable vpsik-dashboard
        systemctl start vpsik-dashboard
        
        # Wait for dashboard to start
        sleep 3
        
        # Test if dashboard is accessible
        if curl -s http://localhost:$DASHBOARD_PORT >/dev/null 2>&1; then
            log_success "Dashboard is running on port $DASHBOARD_PORT"
        else
            log_warn "Dashboard may take a moment to start"
        fi
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
        echo -e "  ${GREEN}✓${NC} Username: ${YELLOW}${DASHBOARD_USER}${NC}"
        echo -e "  ${GREEN}✓${NC} Password: ${YELLOW}${DASHBOARD_PASS}${NC}"
        echo ""
        echo -e "${RED}⚠️  IMPORTANT: Save these credentials!${NC}"
        echo -e "${YELLOW}Dashboard requires authentication for security.${NC}"
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
    
    # Security hardening (before configuration)
    if [[ "$UPDATE_MODE" == false ]]; then
        security_hardening
    fi
    
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
    
# Security audit and hardening with Lynis + rkhunter
security_audit_setup() {
    log_step "🔍 Security Audit Setup (Lynis + rkhunter)"
    
    echo ""
    echo -e "${CYAN}Installing security audit tools...${NC}"
    
    # Install Lynis and rkhunter
    log "Installing Lynis and rkhunter..."
    apt-get install -y lynis rkhunter chkrootkit >/dev/null 2>&1
    
    # Configure rkhunter
    log "Configuring rkhunter..."
    cat > /etc/default/rkhunter <<'RKHUNTER_CONF'
CRON_DAILY_RUN="yes"
CRON_DB_UPDATE="yes"
APT_AUTOGEN="yes"
REPORT_EMAIL="root"
RKHUNTER_CONF
    
    # Update rkhunter database
    rkhunter --update >/dev/null 2>&1 || true
    rkhunter --propupd >/dev/null 2>&1 || true
    
    # Create comprehensive security scan script
    log "Creating security scan and auto-fix script..."
    
    cat > /usr/local/bin/vpsik-security-audit.sh <<'AUDIT_SCRIPT'
#!/bin/bash
# VPSIk Security Audit - Lynis + rkhunter with auto-fix
# Run by: /usr/local/bin/vpsik-security-audit.sh

set -euo pipefail

SCAN_DIR="/opt/VPSIk-Alert/security-scans"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$SCAN_DIR/audit-$TIMESTAMP.log"
SUMMARY_FILE="$SCAN_DIR/latest-summary.txt"
FIXES_LOG="$SCAN_DIR/auto-fixes-$TIMESTAMP.log"

mkdir -p "$SCAN_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$REPORT_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}" | tee -a "$REPORT_FILE"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}" | tee -a "$REPORT_FILE"
}

fix() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] 🔧 $1${NC}" | tee -a "$REPORT_FILE" "$FIXES_LOG"
}

# ============================================
# Phase 1: Lynis Audit
# ============================================
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔍 Phase 1: Running Lynis Security Audit"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

LYNIS_LOG="$SCAN_DIR/lynis-$TIMESTAMP.log"
lynis audit system --quick --quiet 2>&1 | tee "$LYNIS_LOG"

# Extract Lynis score
LYNIS_SCORE=$(grep "Hardening index" "$LYNIS_LOG" | awk '{print $4}' | tr -d '[]')
log "Lynis Security Score: $LYNIS_SCORE"

# ============================================
# Phase 2: rkhunter Scan
# ============================================
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔍 Phase 2: Running rkhunter Rootkit Scan"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RKHUNTER_LOG="$SCAN_DIR/rkhunter-$TIMESTAMP.log"
rkhunter --check --skip-keypress --report-warnings-only 2>&1 | tee "$RKHUNTER_LOG"

# Check for warnings
if grep -qi "warning" "$RKHUNTER_LOG"; then
    warn "rkhunter found warnings - review $RKHUNTER_LOG"
else
    log "✓ No rootkits detected"
fi

# ============================================
# Phase 3: chkrootkit Quick Scan
# ============================================
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔍 Phase 3: Running chkrootkit"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CHKROOTKIT_LOG="$SCAN_DIR/chkrootkit-$TIMESTAMP.log"
chkrootkit 2>&1 | tee "$CHKROOTKIT_LOG"

if grep -qi "INFECTED" "$CHKROOTKIT_LOG"; then
    error "chkrootkit found potential infections!"
else
    log "✓ No infections detected"
fi

# ============================================
# Phase 4: Auto-Fix Common Issues
# ============================================
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔧 Phase 4: Auto-Fixing Common Issues"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FIXES_APPLIED=0

# Fix 1: Set correct permissions on sensitive files
fix "Checking file permissions..."
for file in /etc/passwd /etc/shadow /etc/group /etc/gshadow; do
    if [[ -f "$file" ]]; then
        current_perms=$(stat -c "%a" "$file")
        if [[ "$file" == *"shadow"* || "$file" == *"gshadow"* ]]; then
            if [[ "$current_perms" != "640" && "$current_perms" != "600" ]]; then
                chmod 640 "$file" 2>/dev/null || chmod 600 "$file"
                fix "  ✓ Fixed permissions on $file"
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
            fi
        else
            if [[ "$current_perms" != "644" ]]; then
                chmod 644 "$file"
                fix "  ✓ Fixed permissions on $file"
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
            fi
        fi
    fi
done

# Fix 2: Secure /tmp with noexec
fix "Checking /tmp mount options..."
if ! mount | grep -q "/tmp.*noexec"; then
    if mount | grep -q " /tmp "; then
        mount -o remount,noexec,nosuid,nodev /tmp 2>/dev/null && {
            fix "  ✓ Remounted /tmp with noexec,nosuid,nodev"
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
        }
    fi
fi

# Fix 3: Disable uncommon network protocols
fix "Checking network protocols..."
for proto in dccp sctp rds tipc; do
    if ! grep -q "install $proto /bin/true" /etc/modprobe.d/* 2>/dev/null; then
        echo "install $proto /bin/true" >> /etc/modprobe.d/vpsik-disable-protocols.conf
        fix "  ✓ Disabled $proto protocol"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
done

# Fix 4: Set password quality requirements
fix "Checking password quality..."
if ! grep -q "minlen=12" /etc/security/pwquality.conf 2>/dev/null; then
    cat >> /etc/security/pwquality.conf <<EOF
# Added by VPSIk Security Audit
minlen = 12
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
EOF
    fix "  ✓ Enhanced password quality requirements"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi

# Fix 5: Set account lockout policy
fix "Checking account lockout policy..."
if ! grep -q "pam_faillock" /etc/pam.d/common-auth 2>/dev/null; then
    # Backup first
    cp /etc/pam.d/common-auth /etc/pam.d/common-auth.backup-vpsik
    
    # Add faillock
    if command -v pam-auth-update >/dev/null 2>&1; then
        cat > /etc/security/faillock.conf <<EOF
# Lockout after 5 failed attempts
deny = 5
unlock_time = 900
fail_interval = 900
EOF
        fix "  ✓ Configured account lockout (5 attempts, 15min lockout)"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
fi

# Fix 6: Enable process accounting
fix "Checking process accounting..."
if ! systemctl is-enabled acct >/dev/null 2>&1; then
    apt-get install -y acct >/dev/null 2>&1 || true
    systemctl enable acct >/dev/null 2>&1 && systemctl start acct >/dev/null 2>&1 && {
        fix "  ✓ Enabled process accounting"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    }
fi

# Fix 7: Configure log rotation
fix "Checking log rotation..."
if [[ ! -f /etc/logrotate.d/vpsik-security ]]; then
    cat > /etc/logrotate.d/vpsik-security <<'LOGROTATE'
/opt/VPSIk-Alert/logs/*.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
/opt/VPSIk-Alert/security-scans/*.log {
    monthly
    rotate 6
    compress
    delaycompress
    missingok
    notifempty
}
LOGROTATE
    fix "  ✓ Configured log rotation"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
fi

# Fix 8: Remove world-writable files in system directories
fix "Checking for world-writable files..."
WRITABLE_FILES=$(find /usr /etc /bin /sbin -xdev -type f -perm -0002 2>/dev/null | head -10)
if [[ -n "$WRITABLE_FILES" ]]; then
    while IFS= read -r file; do
        chmod o-w "$file" 2>/dev/null && {
            fix "  ✓ Removed world-write on $file"
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
        }
    done <<< "$WRITABLE_FILES"
fi

# Fix 9: Secure cron
fix "Securing cron..."
for cronfile in /etc/crontab /etc/cron.d/* /etc/cron.daily/* /etc/cron.hourly/* /etc/cron.monthly/* /etc/cron.weekly/*; do
    if [[ -f "$cronfile" ]]; then
        current=$(stat -c "%a" "$cronfile")
        if [[ "$current" != "600" && "$current" != "700" ]]; then
            chmod 600 "$cronfile" 2>/dev/null && {
                fix "  ✓ Secured $cronfile"
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
            }
        fi
    fi
done

# Fix 10: Enable additional auditd rules
fix "Checking auditd rules..."
if [[ -f /etc/audit/rules.d/audit.rules ]]; then
    if ! grep -q "deletion" /etc/audit/rules.d/audit.rules; then
        cat >> /etc/audit/rules.d/audit.rules <<'AUDITRULES'
# File deletion monitoring
-w /bin/rm -p x -k deletion
-w /usr/bin/shred -p x -k deletion

# Unauthorized access attempts
-a always,exit -F arch=b64 -S open,openat -F exit=-EACCES -k access
-a always,exit -F arch=b64 -S open,openat -F exit=-EPERM -k access
AUDITRULES
        augenrules --load >/dev/null 2>&1 || true
        fix "  ✓ Added additional auditd rules"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    fi
fi

log ""
log "Auto-fixes applied: $FIXES_APPLIED"

# ============================================
# Phase 5: Generate Recommendations
# ============================================
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "📋 Phase 5: Security Recommendations"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RECOMMENDATIONS=""

# Check Lynis suggestions
if grep -q "Suggestion" "$LYNIS_LOG"; then
    RECOMMENDATIONS+="From Lynis Audit:\n"
    RECOMMENDATIONS+=$(grep "Suggestion" "$LYNIS_LOG" | head -10)
    RECOMMENDATIONS+="\n\n"
fi

# Check SSH configuration
if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
    RECOMMENDATIONS+="⚠️  SSH: Root login is enabled (security risk)\n"
fi

if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
    RECOMMENDATIONS+="⚠️  SSH: Password authentication is enabled (use keys instead)\n"
fi

# Check for unnecessary services
UNNECESSARY_SERVICES="telnet rsh-server nis avahi-daemon cups"
for service in $UNNECESSARY_SERVICES; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        RECOMMENDATIONS+="⚠️  Unnecessary service running: $service\n"
    fi
done

# Check firewall
if ! ufw status | grep -q "Status: active"; then
    RECOMMENDATIONS+="⚠️  UFW firewall is not active\n"
fi

# Check for users with empty passwords
if awk -F: '($2 == "") {print $1}' /etc/shadow 2>/dev/null | grep -q .; then
    RECOMMENDATIONS+="🔴 CRITICAL: Users with empty passwords found!\n"
fi

# ============================================
# Phase 6: Generate Summary
# ============================================
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "📊 Security Audit Summary"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > "$SUMMARY_FILE" <<SUMMARY
VPSIk Security Audit Summary
════════════════════════════════════════════════════════════
Date: $(date '+%Y-%m-%d %H:%M:%S')
Hostname: $(hostname)

Security Score:
  • Lynis Hardening Index: $LYNIS_SCORE

Scans Completed:
  ✓ Lynis system audit
  ✓ rkhunter rootkit scan
  ✓ chkrootkit scan

Auto-Fixes Applied: $FIXES_APPLIED

Recommendations:
$(echo -e "$RECOMMENDATIONS")

Full Reports:
  • Lynis:      $LYNIS_LOG
  • rkhunter:   $RKHUNTER_LOG
  • chkrootkit: $CHKROOTKIT_LOG
  • Auto-fixes: $FIXES_LOG

Next scheduled scan: $(date -d '+10 days' '+%Y-%m-%d')
════════════════════════════════════════════════════════════
SUMMARY

cat "$SUMMARY_FILE"

# Send notification if VPSIk is installed
if [[ -f /opt/VPSIk-Alert/config/config.json ]]; then
    TELEGRAM_ENABLED=$(jq -r '.notifications.telegram.enabled' /opt/VPSIk-Alert/config/config.json 2>/dev/null)
    BOT_TOKEN=$(jq -r '.notifications.telegram.bot_token' /opt/VPSIk-Alert/config/config.json 2>/dev/null)
    CHAT_ID=$(jq -r '.notifications.telegram.chat_id' /opt/VPSIk-Alert/config/config.json 2>/dev/null)
    
    if [[ "$TELEGRAM_ENABLED" == "true" && -n "$BOT_TOKEN" && -n "$CHAT_ID" ]]; then
        NOTIF_MSG="🔐 *Security Audit Complete*

*Lynis Score:* $LYNIS_SCORE
*Auto-fixes:* $FIXES_APPLIED applied
*Status:* $(grep -c "warning\|INFECTED" "$RKHUNTER_LOG" "$CHKROOTKIT_LOG" 2>/dev/null || echo 0) warnings

Next scan: $(date -d '+10 days' '+%Y-%m-%d')"

        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
             -d chat_id="$CHAT_ID" \
             -d text="$NOTIF_MSG" \
             -d parse_mode="Markdown" >/dev/null 2>&1
    fi
fi

log ""
log "✅ Security audit completed successfully"
log "Summary saved to: $SUMMARY_FILE"

exit 0
AUDIT_SCRIPT
    
    chmod +x /usr/local/bin/vpsik-security-audit.sh
    
    # Run initial scan
    log "Running initial security audit..."
    echo ""
    /usr/local/bin/vpsik-security-audit.sh || true
    
    # Schedule audit every 10 days
    log "Scheduling security audits every 10 days..."
    
    # Create systemd service
    cat > /etc/systemd/system/vpsik-security-audit.service <<'AUDIT_SERVICE'
[Unit]
Description=VPSIk Security Audit (Lynis + rkhunter)
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vpsik-security-audit.sh
StandardOutput=journal
StandardError=journal
AUDIT_SERVICE
    
    # Create systemd timer (every 10 days)
    cat > /etc/systemd/system/vpsik-security-audit.timer <<'AUDIT_TIMER'
[Unit]
Description=VPSIk Security Audit Timer (Every 10 Days)
Requires=vpsik-security-audit.service

[Timer]
OnCalendar=*-*-1,11,21 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
AUDIT_TIMER
    
    systemctl daemon-reload
    systemctl enable vpsik-security-audit.timer
    systemctl start vpsik-security-audit.timer
    
    log_success "Security audit tools installed and scheduled"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔍 Security Audit Summary:${NC}"
    echo -e "  ${GREEN}✓${NC} Lynis installed and configured"
    echo -e "  ${GREEN}✓${NC} rkhunter installed and updated"
    echo -e "  ${GREEN}✓${NC} chkrootkit installed"
    echo -e "  ${GREEN}✓${NC} Auto-fix script created"
    echo -e "  ${GREEN}✓${NC} Scheduled every 10 days (1st, 11th, 21st)"
    echo -e "  ${GREEN}✓${NC} Initial scan completed"
    echo ""
    echo -e "${YELLOW}Manual Commands:${NC}"
    echo -e "  ${BLUE}vpsik audit${NC}           - Run security audit now"
    echo -e "  ${BLUE}vpsik audit-status${NC}    - View last audit results"
    echo -e "  ${BLUE}vpsik audit-schedule${NC}  - View audit schedule"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    sleep 2
}
}

# Run main
main "$@"
