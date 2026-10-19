#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
REPO_DIR="$HOME/sentinel-github-repo"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] EXECUTING AUTONOMOUS VICTORY VALIDATION (V15)\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. التحقق من المزامنة السحابية وإجبار التحديث
echo -e "\e[1;33m[*] TASK 1: Verifying GitHub Auto-Sync...\e[0m"
if [ -f "$HOME/push_updates.sh" ]; then
    cd "$REPO_DIR" || exit 1
    # إضافة ملف التحقق الحالي إلى المستودع للتأكيد
    cp "$HOME/autonomous_victory_validation.sh" "$REPO_DIR/" 2>/dev/null
    ./push_updates.sh > /dev/null 2>&1
    echo -e "\e[1;32m[✓] Auto-Sync Engine Operational. Repository is up to date.\e[0m"
else
    echo -e "\e[1;31m[-] Auto-Sync script missing.\e[0m"
fi
echo -e "\n"

# 2. فحص حالة المنظومة الحية
echo -e "\e[1;33m[*] TASK 2: Verifying Live Environment...\e[0m"
if pgrep -f "sentinel_core.py" > /dev/null; then
    echo -e "\e[1;32m[✓] Core Engine: ONLINE\e[0m"
else
    echo -e "\e[1;31m[!] Core Engine: OFFLINE. Restarting...\e[0m"
    nohup python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
    sleep 2
fi

if pgrep -f "lt --port" > /dev/null || pgrep -f "cloudflared" > /dev/null; then
    echo -e "\e[1;32m[✓] Tunnel Protocol: ACTIVE\e[0m"
else
    echo -e "\e[1;31m[!] Tunnel OFFLINE.\e[0m"
fi
echo -e "\n"

# 3. استخراج الرابط وعرض الالتقاطات
echo -e "\e[1;33m[*] TASK 3: Extracting Target URL & Captured IPs...\e[0m"
TARGET_URL=$(grep -o 'https://[^ ]*\.loca\.lt' "$API_DIR/logs/lt.log" 2>/dev/null | tail -n 1)
if [ -z "$TARGET_URL" ]; then
    TARGET_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$API_DIR/logs/cf.log" 2>/dev/null | tail -n 1)
fi

if [ -n "$TARGET_URL" ]; then
    echo -e "\e[1;34m[+] Current Active URL: \e[1;37m$TARGET_URL\e[0m"
    echo -e "\e[1;34m[+] Recent Captured IPs:\e[0m"
    echo -e "\e[1;37m-------------------------------------------------\e[0m"
    tail -n 5 "$LOG_FILE"
    echo -e "\e[1;37m-------------------------------------------------\e[0m"
else
    echo -e "\e[1;31m[-] Could not retrieve active URL.\e[0m"
fi
echo -e "\n"

# 4. تفعيل الرادار (إعادة تشغيل جلسة tmux)
echo -e "\e[1;33m[*] TASK 4: Re-Arming Live Radar (tmux)...\e[0m"
tmux kill-session -t sentinel_monitor 2>/dev/null
tmux new-session -d -s sentinel_monitor "tail -f $LOG_FILE"
echo -e "\e[1;32m[✓] Radar session is LIVE and tracking incoming connections.\e[0m"

echo -e "\n\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] ALL SYSTEMS GO. MISSION VALIDATED.\e[0m"
echo -e "\e[1;36m[*] TO MONITOR LIVE: \e[1;37mtmux attach -t sentinel_monitor\e[0m"
echo -e "\e[1;36m[*] TO STOP SYSTEM: \e[1;37mpkill -9 -f sentinel_core.py; pkill -9 -f lt; pkill -9 -f cloudflared; termux-wake-unlock; tmux kill-server\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
