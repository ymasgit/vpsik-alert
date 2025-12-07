#!/usr/bin/env bash
# VPSIk Alert Installer v5.0 - محسَّنة ومتكاملة
# - ينشئ venv للداشبورد
# - ينشئ مستخدم غير root لتشغيل الخدمة
# - يحتوي على Uninstall
# - تحقق من مدخلات (Telegram/Email/Webhooks)
# - تحسن التعامل مع systemd, logging, وملفات النسخ الاحتياطي
# Usage: sudo ./vpsik-alert-installer-v5.0.sh
set -euo pipefail
IFS=$'\n\t'

VERSION="5.0.0"
INSTALL_DIR="/opt/VPSIk-Alert"
REPO="https://github.com/ymasgit/vpsik-alert.git"
LOCK="/tmp/vpsik-install.lock"
LOG="/var/log/vpsik-installer.log"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
SERVICE_USER="vpsik"

# --- Helpers ---------------------------------------------------------------
log(){ echo "$(date -Iseconds) - $*" | tee -a "$LOG"; }
err(){ echo -e "${RED}ERROR:${NC} $*" | tee -a "$LOG"; }
info(){ echo -e "${GREEN}$*${NC}" | tee -a "$LOG"; }

# --- CLI options ----------------------------------------------------------
if [[ ${1-} == "--uninstall" ]]; then
    echo "سيتم إزالة VPSIk Alert..." | tee -a "$LOG"
    systemctl stop vpsik.timer vpsik.service vpsik-dashboard.service 2>/dev/null || true
    systemctl disable vpsik.timer vpsik.service vpsik-dashboard.service 2>/dev/null || true
    rm -f /etc/systemd/system/vpsik* 2>/dev/null || true
    rm -rf "$INSTALL_DIR" || true
    userdel -r "$SERVICE_USER" 2>/dev/null || true
    rm -f "$LOCK" 2>/dev/null || true
    systemctl daemon-reload
    echo "تمت إزالة النظام." | tee -a "$LOG"
    exit 0
fi

# --- require root --------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    err "هذا السكربت يجب أن يُشغّل كـ root"
    exit 1
fi

# --- lock ---------------------------------------------------------------
if [[ -f "$LOCK" ]]; then
    err "تثبيت جارٍ أو تم ترك ملف القفل: $LOCK"; exit 1
fi
trap 'rm -f "$LOCK"; exit' EXIT
touch "$LOCK"
exec &> >(tee -a "$LOG")

# --- detect package manager ---------------------------------------------
if [[ -f /etc/debian_version ]]; then
    PKG_MGR="apt"
elif [[ -f /etc/redhat-release ]]; then
    PKG_MGR="yum"
else
    err "نظام تشغيل غير مدعوم - استخدم Debian/Ubuntu/CentOS/RHEL"
    exit 1
fi

# --- ensure basic tools -------------------------------------------------
install_pkgs(){
    if [[ "$PKG_MGR" == "apt" ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y --no-install-recommends git python3 python3-venv python3-pip sqlite3 nginx jq bc fail2ban rkhunter net-tools ufw curl wget whiptail || true
    else
        yum install -y epel-release
        yum install -y git python3 python3-pip sqlite nginx jq bc fail2ban rkhunter net-tools ufw curl wget newt || true
    fi
}

install_pkgs

# --- create service user ------------------------------------------------
if ! id -u "$SERVICE_USER" &>/dev/null; then
    useradd -r -s /usr/sbin/nologin -M "$SERVICE_USER" || true
    info "Created service user: $SERVICE_USER"
fi

# --- interactive with whiptail (fallback to read if no tty) ------------
USE_WHITEL=false
if command -v whiptail &>/dev/null && [ -t 1 ]; then
    USE_WHITEL=true
fi
ask(){
    local prompt="$1" default_val="${2-}"
    if $USE_WHITEL; then
        whiptail --inputbox "$prompt" 10 70 "$default_val" 3>&1 1>&2 2>&3
    else
        read -rp "$prompt ($default_val): " val
        echo "${val:-$default_val}"
    fi
}
confirm(){
    local prompt="$1"
    if $USE_WHITEL; then
        whiptail --yesno "$prompt" 8 60
        return $?
    else
        read -rp "$prompt [y/N]: " ans
        [[ "$ans" =~ ^[Yy] ]] && return 0 || return 1
    fi
}

# --- language (simple) --------------------------------------------------
LANG_CHOICE="ar"
if $USE_WHITEL; then
    LANG_CHOICE=$(whiptail --title "اللغة / Language" --menu "اختر لغة" 12 60 2 "ar" "العربية" "en" "English" 3>&1 1>&2 2>&3)
fi

# --- inputs -------------------------------------------------------------
ALERT_NAME=$(ask "اسم السيرفر في الاشعارات" "$(hostname -f)")

NOTIF=$(whiptail --title "وسيلة الاشعارات" --menu "اختر" 15 60 5 \
    "telegram" "Telegram" \
    "email"    "Email (SMTP)" \
    "discord"  "Discord Webhook" \
    "slack"    "Slack Webhook" \
    "none"     "Logs Only" 3>&1 1>&2 2>&3)

TOKEN=""; CHAT_ID=""; EMAIL_TO=""; DISCORD_WEBHOOK=""; SLACK_WEBHOOK=""

validate_email(){
    [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}
validate_url(){
    [[ "$1" =~ ^https?://.+ ]]
}

case "$NOTIF" in
    telegram)
        TOKEN=$(ask "Telegram Bot Token (from @BotFather)" "")
        CHAT_ID=$(ask "Telegram Chat ID" "")
        if ! curl -s --max-time 7 "https://api.telegram.org/bot$TOKEN/getMe" | jq -e '.ok' &>/dev/null; then
            err "فشل التحقق من Telegram token. تأكد من صحة التوكن."; exit 1
        fi
        info "Telegram token OK"
        ;;
    email)
        EMAIL_TO=$(ask "Recipient Email" "")
        if ! validate_email "$EMAIL_TO"; then err "بريد غير صحيح"; exit 1; fi
        ;;
    discord)
        DISCORD_WEBHOOK=$(ask "Discord Webhook URL" "")
        if ! validate_url "$DISCORD_WEBHOOK"; then err "Discord webhook غير صحيح"; exit 1; fi
        ;;
    slack)
        SLACK_WEBHOOK=$(ask "Slack Webhook URL" "")
        if ! validate_url "$SLACK_WEBHOOK"; then err "Slack webhook غير صحيح"; exit 1; fi
        ;;
esac

# --- dashboard choice --------------------------------------------------
if confirm "هل تريد تثبيت لوحة تحكم ويب؟"; then
    DASHBOARD=true
    # أمنياً نولد منفذ ونحاول التحقق من التوفر
    for i in {1..50}; do
        PORT=$((10000 + RANDOM % 40000))
        if ! ss -tlnp 2>/dev/null | grep -q ":$PORT "; then break; fi
    done
    DASH_USER=$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)
    DASH_PASS=$(tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c 16)
else
    DASHBOARD=false
fi

# --- security options --------------------------------------------------
SECURITY=$(whiptail --title "خيارات الأمان" --checklist "اختر عناصر الأمان" 16 70 5 \
    "ssh"       "Disable Root + SSH Key Only" ON \
    "ufw"       "Enable UFW Firewall" ON \
    "fail2ban"  "Brute Force Protection" ON \
    "updates"   "Automatic Security Updates" ON \
    "audit"     "Schedule Security Scan every 10 days" ON 3>&1 1>&2 2>&3)

# --- summary -----------------------------------------------------------
SUMMARY="Server: $ALERT_NAME\nNotify: $NOTIF\nDashboard: $([ "$DASHBOARD" = true ] && echo "Yes - $PORT" || echo "No")\nSecurity: $SECURITY"
if $USE_WHITEL; then
    whiptail --title "ملخص التثبيت" --msgbox "$SUMMARY" 14 70
else
    echo -e "$SUMMARY"
fi

# --- prepare install dir -----------------------------------------------
mkdir -p "$INSTALL_DIR"
chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR" || true
chmod 750 "$INSTALL_DIR"

# --- clone repo (shallow) ---------------------------------------------
tmpdir=$(mktemp -d)
log "Cloning repo..."
if git clone --depth 1 "$REPO" "$tmpdir"; then
    rsync -a --exclude='.git' "$tmpdir/" "$INSTALL_DIR/"
else
    err "فشل استنساخ الريبو. حاول لاحقًا أو استخدم نسخة محلية."; rm -rf "$tmpdir"; exit 1
fi
rm -rf "$tmpdir"

# --- create venv if dashboard requested --------------------------------
if [ "$DASHBOARD" = true ]; then
    info "إنشاء Python virtualenv للداشبورد"
    python3 -m venv "$INSTALL_DIR/dashboard/venv"
    "$INSTALL_DIR/dashboard/venv/bin/pip" install --upgrade pip setuptools wheel
    if [[ -f "$INSTALL_DIR/dashboard/requirements.txt" ]]; then
        "$INSTALL_DIR/dashboard/venv/bin/pip" install -r "$INSTALL_DIR/dashboard/requirements.txt"
    fi
    chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR/dashboard/venv"
fi

# --- generate config --------------------------------------------------
CFG_FILE="$INSTALL_DIR/config/config.json"
mkdir -p "$(dirname "$CFG_FILE")"
cat > "$CFG_FILE" <<EOF
{
  "version": "$VERSION",
  "alert_name": "${ALERT_NAME}",
  "notifications": {
    "telegram": {"enabled": ${NOTIF==telegram}, "token": "${TOKEN}", "chat_id": "${CHAT_ID}"},
    "email": {"enabled": ${NOTIF==email}, "to": "${EMAIL_TO}"},
    "discord": {"enabled": ${NOTIF==discord}, "webhook": "${DISCORD_WEBHOOK}"},
    "slack": {"enabled": ${NOTIF==slack}, "webhook": "${SLACK_WEBHOOK}"}
  },
  "dashboard": {"enabled": ${DASHBOARD}, "port": ${PORT:-0}},
  "security": []
}
EOF
chmod 600 "$CFG_FILE"
chown "$SERVICE_USER":"$SERVICE_USER" "$CFG_FILE"

# --- write security array using jq if present --------------------------
if [[ -n "$SECURITY" ]]; then
    SECURITY_ARR=$(echo "$SECURITY" | tr ' ' '\n' | jq -R . | jq -s .)
    tmpfile=$(mktemp)
    jq ".security = $SECURITY_ARR" "$CFG_FILE" > "$tmpfile" && mv "$tmpfile" "$CFG_FILE"
fi

# --- systemd unit: monitor (timer + service) ---------------------------
cat > /etc/systemd/system/vpsik.service <<'UNIT'
[Unit]
Description=VPSIk Alert Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash /opt/VPSIk-Alert/scripts/monitor.sh
WorkingDirectory=/opt/VPSIk-Alert
User=vpsik

[Install]
WantedBy=multi-user.target
UNIT

cat > /etc/systemd/system/vpsik.timer <<'UNIT'
[Unit]
Description=Run VPSIk Alert Monitor periodically

[Timer]
OnBootSec=1min
OnUnitActiveSec=300
Persistent=true

[Install]
WantedBy=timers.target
UNIT

# --- systemd unit: dashboard -------------------------------------------
if [ "$DASHBOARD" = true ]; then
    cat > /etc/systemd/system/vpsik-dashboard.service <<EOF
[Unit]
Description=VPSIk Dashboard
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/dashboard
ExecStart=$INSTALL_DIR/dashboard/venv/bin/python $INSTALL_DIR/dashboard/app.py
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload
systemctl enable --now vpsik.timer
if [ "$DASHBOARD" = true ]; then
    systemctl enable --now vpsik-dashboard.service
fi

# --- permissions -------------------------------------------------------
chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR"
find "$INSTALL_DIR" -type d -exec chmod 750 {} +
find "$INSTALL_DIR" -type f -exec chmod 640 {} +

# --- firewall (basic) -------------------------------------------------
if [[ "$PKG_MGR" == "apt" ]]; then
    if command -v ufw &>/dev/null && confirm "تفعيل UFW بفتح منفذ SSH وداشبورد $PORT (إن وُجد)؟"; then
        ufw allow OpenSSH
        if [ "$DASHBOARD" = true ]; then ufw allow "$PORT"; fi
        ufw --force enable
    fi
fi

# --- final messages ---------------------------------------------------
if [ "$DASHBOARD" = true ]; then
    IP=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
    if $USE_WHITEL; then
        whiptail --title "تم التثبيت" --msgbox "VPSIk Alert v$VERSION مثبت!\nURL: http://$IP:$PORT\nUsername: $DASH_USER\nPassword: $DASH_PASS\n\nاحفظ هذه البيانات." 15 70
    else
        echo -e "\nVPSIk Alert v$VERSION installed.\nDashboard: http://$IP:$PORT\nUser: $DASH_USER\nPass: $DASH_PASS\n"
    fi
else
    if $USE_WHITEL; then
        whiptail --title "تم التثبيت" --msgbox "VPSIk Alert v$VERSION مثبت!\nNotifications: $NOTIF" 10 60
    else
        echo "VPSIk Alert v$VERSION installed. Notifications: $NOTIF"
    fi
fi

log "Installation finished successfully"
rm -f "$LOCK"

# --- helper: create uninstall script for convenience ------------------
cat > /usr/local/bin/vpsik-uninstall <<'SH'
#!/usr/bin/env bash
set -e
if [[ $EUID -ne 0 ]]; then echo "Run as root"; exit 1; fi
systemctl stop vpsik.timer vpsik.service vpsik-dashboard.service 2>/dev/null || true
systemctl disable vpsik.timer vpsik.service vpsik-dashboard.service 2>/dev/null || true
rm -f /etc/systemd/system/vpsik* 2>/dev/null || true
rm -rf /opt/VPSIk-Alert 2>/dev/null || true
userdel -r vpsik 2>/dev/null || true
systemctl daemon-reload
echo "VPSIk removed"
SH
chmod +x /usr/local/bin/vpsik-uninstall

info "Created uninstall helper: /usr/local/bin/vpsik-uninstall"

exit 0
