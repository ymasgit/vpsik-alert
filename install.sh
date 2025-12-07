#!/usr/bin/env bash
# VPSIk Alert v5.1 - مُحسَّن، آمن، ومستقر
# يدعم Ubuntu/Debian/CentOS/Rocky — مع واجهة عربية/إنجليزية اختيارية
set -euo pipefail
IFS=$'\n\t'

# === المتغيرات ===
VERSION="5.1.0"
INSTALL_DIR="/opt/VPSIk-Alert"
REPO="https://github.com/ymasgit/vpsik-alert.git"  # ✅ مسافات زائدة أُزيلت
LOCK="/tmp/vpsik-install.lock"
LOG="/var/log/vpsik-installer.log"
SERVICE_USER="vpsik"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] $*${NC}" | tee -a "$LOG"; }
err() { echo -e "${RED}خطأ: $*${NC}" | tee -a "$LOG"; exit 1; }

# === التحقق الأولي ===
[[ $EUID -ne 0 ]] && err "يجب تشغيل السكربت كـ root"
[[ -f "$LOCK" ]] && err "التثبيت قيد التنفيذ بالفعل"
touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT
exec &> >(tee -a "$LOG")

# === Whiptail + Fallback ===
USE_WHIPT=false
if command -v whiptail &>/dev/null && [ -t 1 ]; then
    USE_WHIPT=true
fi

ask() {
    local prompt="$1" default="${2-}"
    if $USE_WHIPT; then
        whiptail --inputbox "$prompt" 10 70 "${default}" 3>&1 1>&2 2>&3
    else
        read -rp "$prompt [${default}]: " val
        echo "${val:-$default}"
    fi
}

confirm() {
    local prompt="$1"
    if $USE_WHIPT; then
        whiptail --yesno "$prompt" 10 60
    else
        read -rp "$prompt [y/N]: " ans
        [[ "${ans,,}" == "y" ]]
    fi
}

# === اكتشاف النظام ===
if [ ! -f /etc/os-release ]; then err "نظام غير مدعوم"; fi
. /etc/os-release

case "$ID" in
    ubuntu|debian)
        PKG_MGR="apt"; FIREWALL="ufw"
        ;;
    centos|rhel|almalinux|rocky)
        PKG_MGR="yum"; FIREWALL="firewalld"
        ;;
    *)
        err "نظام $ID غير مدعوم. يُرجى استخدام Ubuntu/Debian/CentOS/Rocky"
        ;;
esac

# === التثبيت مع Progress Bar (إذا متوفر) ===
if $USE_WHIPT; then
    install_with_progress() {
        {
            echo 5; echo "XXX"; echo "تحديث النظام وتثبيت التبعيات..."; echo "XXX"
            if [[ "$PKG_MGR" == "apt" ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get update -qq
                DEBIAN_FRONTEND=noninteractive apt-get install -y git python3 python3-venv python3-pip sqlite3 nginx jq bc fail2ban rkhunter lynis net-tools ufw curl wget whiptail
            else
                yum install -y epel-release
                yum install -y git python3 python3-pip sqlite nginx jq bc fail2ban rkhunter lynis net-tools firewalld curl wget newt
            fi

            echo 20; echo "XXX"; echo "إنشاء مستخدم الخدمة..."; echo "XXX"
            id -u "$SERVICE_USER" &>/dev/null || useradd -r -s /usr/sbin/nologin -M "$SERVICE_USER"

            echo 40; echo "XXX"; echo "تنزيل الملفات من GitHub..."; echo "XXX"
            TMP_DIR=$(mktemp -d)
            git clone --depth 1 "$REPO" "$TMP_DIR" || err "فشل تنزيل المستودع"
            mkdir -p "$INSTALL_DIR"
            rsync -a --exclude='.git' "$TMP_DIR/" "$INSTALL_DIR/" || true
            rm -rf "$TMP_DIR"

            echo 70; echo "XXX"; echo "إعداد الهيكل الأساسي..."; echo "XXX"
            mkdir -p "$INSTALL_DIR"/{config,logs,database,scripts,dashboard/{templates,static},security/scans}
            chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR"
        } | whiptail --title "جارٍ التثبيت..." --gauge "الرجاء الانتظار" 8 70 0
    }
    install_with_progress
else
    log "تحديث النظام وتثبيت التبعيات..."
    if [[ "$PKG_MGR" == "apt" ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y git python3 python3-venv python3-pip sqlite3 nginx jq bc fail2ban rkhunter lynis net-tools ufw curl wget
    else
        yum install -y epel-release
        yum install -y git python3 python3-pip sqlite nginx jq bc fail2ban rkhunter lynis net-tools firewalld curl wget
    fi

    log "إنشاء مستخدم الخدمة..."
    id -u "$SERVICE_USER" &>/dev/null || useradd -r -s /usr/sbin/nologin -M "$SERVICE_USER"

    log "تنزيل الملفات..."
    TMP_DIR=$(mktemp -d)
    git clone --depth 1 "$REPO" "$TMP_DIR" || err "فشل التنزيل"
    mkdir -p "$INSTALL_DIR"
    rsync -a --exclude='.git' "$TMP_DIR/" "$INSTALL_DIR/" || true
    rm -rf "$TMP_DIR"

    log "إعداد المجلدات..."
    mkdir -p "$INSTALL_DIR"/{config,logs,database,scripts,dashboard/{templates,static},security/scans}
    chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR"
fi

# === التهيئة التفاعلية ===
ALERT_NAME=$(ask "اسم الخادم في الإشعارات" "$(hostname -f)")

NOTIF=$(whiptail --menu "اختر وسيلة الإشعارات" 16 65 5 \
    "telegram" "Telegram (موصى به)" \
    "email" "بريد إلكتروني" \
    "discord" "Discord Webhook" \
    "slack" "Slack Webhook" \
    "none" "سجلات فقط" 3>&1 1>&2 2>&3)

TOKEN=""; CHAT_ID=""; EMAIL_TO=""; DISCORD_WEBHOOK=""; SLACK_WEBHOOK=""

case "$NOTIF" in
    telegram)
        TOKEN=$(ask "Telegram Bot Token (من @BotFather)")
        CHAT_ID=$(ask "Telegram Chat ID (من @userinfobot)")
        # ✅ إصلاح المسافة في الرابط
        if ! curl -s "https://api.telegram.org/bot$TOKEN/getMe" | grep -q '"ok":true'; then
            err "فشل الاتصال ببوت Telegram. تحقق من التوكن والـ Chat ID"
        fi
        ;;
    email) EMAIL_TO=$(ask "البريد الإلكتروني المستقبل") ;;
    discord) DISCORD_WEBHOOK=$(ask "Discord Webhook URL") ;;
    slack) SLACK_WEBHOOK=$(ask "Slack Webhook URL") ;;
esac

DASHBOARD=false
if confirm "هل تريد تثبيت لوحة تحكم ويب؟"; then
    DASHBOARD=true
    while :; do
        PORT=$((10000 + RANDOM % 40000))
        ! ss -tlnp 2>/dev/null | grep -q ":$PORT " && break
    done
    DASH_USER=$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)
    DASH_PASS=$(tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c 16)
fi

INTERVAL=$(whiptail --menu "فاصل الفحص" 12 60 4 \
    "60" "كل دقيقة" \
    "300" "كل 5 دقائق (افتراضي)" \
    "900" "كل 15 دقيقة" \
    "1800" "كل 30 دقيقة" 3>&1 1>&2 2>&3)
INTERVAL=${INTERVAL:-300}

SECURITY=$(whiptail --checklist "خيارات الأمان" 16 70 5 \
    "ssh" "تعطيل Root SSH" ON \
    "firewall" "تفعيل الجدار الناري" ON \
    "fail2ban" "الحماية من Brute Force" ON \
    "updates" "تحديثات أمنية تلقائية" ON \
    "audit" "فحص أمني كل 10 أيام" ON 3>&1 1>&2 2>&3)

# === كتابة ملف الإعدادات ===
cat > "$INSTALL_DIR/config/config.json" <<EOF
{
  "version": "$VERSION",
  "alert_name": "$ALERT_NAME",
  "check_interval": $INTERVAL,
  "notifications": {
    "telegram": {"enabled": $([[ "$NOTIF" == "telegram" ]] && echo true || echo false), "token": "$TOKEN", "chat_id": "$CHAT_ID"},
    "email": {"enabled": $([[ "$NOTIF" == "email" ]] && echo true || echo false), "to": "$EMAIL_TO"},
    "discord": {"enabled": $([[ "$NOTIF" == "discord" ]] && echo true || echo false), "webhook": "$DISCORD_WEBHOOK"},
    "slack": {"enabled": $([[ "$NOTIF" == "slack" ]] && echo true || echo false), "webhook": "$SLACK_WEBHOOK"}
  },
  "dashboard": {"enabled": $DASHBOARD, "port": $PORT},
  "security": []
}
EOF

# تحديث security array بشكل آمن
if [[ -n "$SECURITY" ]]; then
    SECURITY_ARR=$(printf '%s\n' $SECURITY | jq -R . | jq -s .)
    tmpfile=$(mktemp)
    jq ".security = $SECURITY_ARR" "$INSTALL_DIR/config/config.json" > "$tmpfile" && mv "$tmpfile" "$INSTALL_DIR/config/config.json"
fi

chmod 600 "$INSTALL_DIR/config/config.json"
chown "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR/config/config.json"

# === إعداد بيئة الداشبورد ===
if [[ "$DASHBOARD" == true ]]; then
    log "إعداد بيئة Python للداشبورد..."
    python3 -m venv "$INSTALL_DIR/dashboard/venv"
    "$INSTALL_DIR/dashboard/venv/bin/pip" install flask flask-login
    chown -R "$SERVICE_USER":"$SERVICE_USER" "$INSTALL_DIR/dashboard/venv"

    # حفظ بيانات الدخول بشكل منفصل وآمن
    CRED_FILE="$INSTALL_DIR/config/.dashboard_auth"
    echo "user:$DASH_USER" > "$CRED_FILE"
    echo "pass:$DASH_PASS" >> "$CRED_FILE"
    chmod 600 "$CRED_FILE"
    chown "$SERVICE_USER":"$SERVICE_USER" "$CRED_FILE"
fi

# === خدمات systemd (صحيحة وفق المعايير) ===
cat > /etc/systemd/system/vpsik.service <<EOF
[Unit]
Description=VPSIk Monitor
After=network.target

[Service]
Type=oneshot
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/scripts/monitor.sh

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/vpsik.timer <<EOF
[Unit]
Description=VPSIk Timer
After=network.target

[Timer]
OnBootSec=1min
OnUnitActiveSec=$INTERVAL
Persistent=true

[Install]
WantedBy=timers.target
EOF

if [[ "$DASHBOARD" == true ]]; then
    cat > /etc/systemd/system/vpsik-dashboard.service <<EOF
[Unit]
Description=VPSIk Dashboard
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/dashboard
ExecStart=$INSTALL_DIR/dashboard/venv/bin/python app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF
fi

systemctl daemon-reload
systemctl enable --now vpsik.timer
[[ "$DASHBOARD" == true ]] && systemctl enable --now vpsik-dashboard

# === تهيئة الجدار الناري ===
if [[ "$SECURITY" == *"firewall"* ]]; then
    if [[ "$FIREWALL" == "ufw" ]]; then
        ufw allow OpenSSH
        [[ "$DASHBOARD" == true ]] && ufw allow "$PORT"
        ufw --force enable
    else
        systemctl enable --now firewalld
        firewall-cmd --add-service=ssh --permanent
        [[ "$DASHBOARD" == true ]] && firewall-cmd --add-port="$PORT"/tcp --permanent
        firewall-cmd --reload
    fi
fi

# === أمر CLI (vpsik) ===
cat > /usr/local/bin/vpsik <<'CMD'
#!/usr/bin/env bash
case "${1:-}" in
    status) systemctl status vpsik.timer vpsik-dashboard --no-pager ;;
    logs) journalctl -u vpsik -f ;;
    test) sudo -u vpsik /opt/VPSIk-Alert/scripts/monitor.sh ;;
    restart) systemctl restart vpsik.timer vpsik-dashboard ;;
    audit) /usr/local/bin/vpsik-audit ;;
    config) nano /opt/VPSIk-Alert/config/config.json ;;
    uninstall) echo "استخدم: sudo /opt/VPSIk-Alert/uninstall.sh" ;;
    *) echo "الاستخدام: vpsik [status|logs|test|restart|audit|config|uninstall]" ;;
esac
CMD
chmod +x /usr/local/bin/vpsik

# === فحص أمني دوري ===
if [[ "$SECURITY" == *"audit"* ]]; then
    cat > /usr/local/bin/vpsik-audit <<'AUDIT'
#!/usr/bin/env bash
mkdir -p /opt/VPSIk-Alert/security/scans
/usr/bin/lynis audit system --quiet > /opt/VPSIk-Alert/security/scans/lynis-$(date +%F).log 2>&1
/usr/bin/rkhunter --check --skip-keypress --nocolors > /opt/VPSIk-Alert/security/scans/rkhunter-$(date +%F).log 2>&1
AUDIT
    chmod +x /usr/local/bin/vpsik-audit
    echo "0 3 */10 * * root /usr/local/bin/vpsik-audit" > /etc/cron.d/vpsik-audit
fi

# === رسالة النهاية ===
IP=$(hostname -I | awk '{print $1}')
if [[ "$DASHBOARD" == true ]]; then
    MSG="VPSIk Alert v$VERSION جاهز!\n\nلوحة التحكم: http://$IP:$PORT\nالمستخدم: $DASH_USER\nالمرور: $DASH_PASS\n\nاحفظ هذه البيانات!\n\nاستخدم: vpsik status"
    $USE_WHIPT && whiptail --title "تم بنجاح!" --msgbox "$MSG" 18 70 || echo -e "\n$MESSAGE\n"
else
    MSG="✅ تم تثبيت VPSIk Alert بنجاح!\nالإشعارات: $NOTIF\nاستخدم: vpsik status"
    $USE_WHIPT && whiptail --msgbox "$MSG" 10 60 || echo -e "\n$MESSAGE\n"
fi

log "VPSIk Alert v$VERSION مُثبّت ومُفعّل بنجاح."
