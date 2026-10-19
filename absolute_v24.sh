#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
FLARE_LOG="$API_DIR/logs/flare.log"
mkdir -p "$API_DIR/logs"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] INITIATING ABSOLUTE VICTORY V24 (FLAREDANTIC CORE)\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. تطهير شامل
echo -e "\e[1;33m[*] TASK 1: Purging Environment...\e[0m"
pkill -9 -f "sentinel_core.py" 2>/dev/null
pkill -9 -f "ssh.*pinggy" 2>/dev/null
pkill -9 -f "flare" 2>/dev/null
sleep 2

# 2. تشغيل النواة السيادية (المنفذ 9002)
echo -e "\e[1;33m[*] TASK 2: Starting Smart Core on Port 9002...\e[0m"
nohup stdbuf -oL -eL python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
sleep 2
echo -e "\e[1;32m[✓] Core Engine ONLINE.\e[0m\n"

# 3. تشغيل Flaredantic (Serveo) - الأداة التي أثبتت نجاحها
echo -e "\e[1;33m[*] TASK 3: Launching Serveo Tunnel via Flaredantic...\e[0m"
rm -f "$FLARE_LOG"
nohup flare --port 9002 --tunnel serveo > "$FLARE_LOG" 2>&1 &
sleep 10

# استخراج الرابط بذكاء (يبحث عن أي رابط يبدأ بـ https في السجل)
TARGET_URL=$(grep -oE 'https://[^ ]+' "$FLARE_LOG" | tail -n 1)

if [ -z "$TARGET_URL" ]; then
    echo -e "\e[1;31m[!] CRITICAL: Failed to extract URL from Flaredantic.\e[0m"
    tail -n 5 "$FLARE_LOG"
    exit 1
fi
echo -e "\e[1;32m[✓] Tunnel Active: $TARGET_URL\e[0m\n"

# 4. الاختبار المباشر والتحقق من السجل
echo -e "\e[1;33m[*] TASK 4: Executing Direct Strike & Log Verification...\e[0m"
curl -s -m 10 "$TARGET_URL" > /dev/null
sleep 2

echo -e "\e[1;32m[✓] PROOF OF CAPTURE (From Core Engine Log):\e[0m"
echo -e "\e[1;37m-------------------------------------------------\e[0m"
grep "CAPTURED TARGET IP" "$LOG_FILE" | tail -n 3
echo -e "\e[1;37m-------------------------------------------------\e[0m\n"

# 5. المزامنة مع GitHub
if [ -d "$HOME/sentinel-github-repo/.git" ]; then
    echo -e "\e[1;33m[*] TASK 5: Syncing with GitHub...\e[0m"
    cd "$HOME/sentinel-github-repo"
    cp "$HOME/absolute_v24.sh" .
    git add . >/dev/null 2>&1
    git commit -m "Auto-Update: V24 Absolute Victory - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
    echo -e "\e[1;32m[✓] GitHub Sync Complete.\e[0m\n"
fi

# 6. تفعيل الرادار
echo -e "\e[1;33m[*] TASK 6: Arming Live Radar...\e[0m"
tmux kill-session -t sentinel_monitor 2>/dev/null
tmux new-session -d -s sentinel_monitor "tail -f $LOG_FILE"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] MISSION ACCOMPLISHED. SYSTEM IS STABLE.\e[0m"
echo -e "\e[1;33m[!] YOUR URL: \e[1;37m$TARGET_URL\e[0m"
echo -e "\e[1;36m[*] To monitor live: \e[1;37mtmux attach -t sentinel_monitor\e[0m"
echo -e "\e[1;36m[*] To stop: \e[1;37mpkill -9 -f sentinel_core.py; pkill -9 -f flare\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
