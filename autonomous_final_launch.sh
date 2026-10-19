#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
FLARE_LOG="$API_DIR/logs/flare.log"
REPO_DIR="$HOME/sentinel-github-repo"
mkdir -p "$API_DIR/logs"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] INITIATING AUTONOMOUS FINAL LAUNCH (V28)\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. التطهير الشامل وإيقاف العمليات القديمة
echo -e "\e[1;33m[*] TASK 1: Purging Environment...\e[0m"
pkill -9 -f "sentinel_core.py" 2>/dev/null
pkill -9 -f "flare" 2>/dev/null
sleep 3
> "$LOG_FILE"
> "$FLARE_LOG"

# 2. تشغيل النواة السيادية (المنفذ 9002)
echo -e "\e[1;33m[*] TASK 2: Starting Core Engine (Port 9002)...\e[0m"
nohup stdbuf -oL -eL python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
sleep 2

# 3. تشغيل نفق Serveo
echo -e "\e[1;33m[*] TASK 3: Launching Serveo Tunnel...\e[0m"
nohup flare --port 9002 --tunnel serveo > "$FLARE_LOG" 2>&1 &
sleep 10

TARGET_URL=$(grep -oE 'https://[^ ]+' "$FLARE_LOG" | tail -n 1)
if [ -z "$TARGET_URL" ]; then
    echo -e "\e[1;31m[!] CRITICAL: Failed to extract URL.\e[0m"
    exit 1
fi

# 4. الاختبار المحلي (لإثبات عمل السجل)
echo -e "\e[1;33m[*] TASK 4: Executing Internal Strike (Proof of Capture)...\e[0m"
curl -s -m 5 http://127.0.0.1:9002 > /dev/null
sleep 1

# 5. المزامنة مع GitHub
if [ -d "$REPO_DIR/.git" ]; then
    echo -e "\e[1;33m[*] TASK 5: Syncing with GitHub...\e[0m"
    cd "$REPO_DIR"
    cp "$HOME/autonomous_final_launch.sh" .
    git add . >/dev/null 2>&1
    git commit -m "Auto-Update: V28 Final Launch - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
fi

# 6. تفعيل الرادار
echo -e "\e[1;33m[*] TASK 6: Arming Live Radar...\e[0m"
tmux kill-session -t sentinel_monitor 2>/dev/null
tmux new-session -d -s sentinel_monitor "tail -f $LOG_FILE"

# 7. التقرير النهائي
echo -e "\n\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] SYSTEM IS LIVE AND RUNNING IN PERSISTENT MODE.\e[0m"
echo -e "\e[1;33m[!] YOUR TARGET URL: \e[1;37m$TARGET_URL\e[0m\n"

echo -e "\e[1;32m[✓] Internal Capture Proof (From Log):\e[0m"
tail -n 1 "$LOG_FILE"
echo -e "\n"

echo -e "\e[1;33m[*] OPERATIONAL INSTRUCTIONS:\e[0m"
echo -e "    1. To test from outside (Bypass ISP Loopback): Turn off Wi-Fi (or Data) and open the URL in your browser."
echo -e "    2. To monitor live captures: \e[1;37mtmux attach -t sentinel_monitor\e[0m"
echo -e "    3. To stop system: \e[1;37mpkill -9 -f sentinel_core.py; pkill -9 -f flare; tmux kill-server\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
