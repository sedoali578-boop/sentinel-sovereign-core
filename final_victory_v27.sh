#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
FLARE_LOG="$API_DIR/logs/flare.log"
REPO_DIR="$HOME/sentinel-github-repo"
mkdir -p "$API_DIR/logs"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] CONSOLIDATING VICTORY (V27 - PERSISTENT MODE)\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. تطهير شامل
pkill -9 -f "sentinel_core.py" 2>/dev/null
pkill -9 -f "flare" 2>/dev/null
sleep 3

# 2. تشغيل النواة السيادية
echo -e "\e[1;33m[*] TASK 1: Starting Core Engine (Unbuffered)...\e[0m"
nohup stdbuf -oL -eL python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
sleep 2

# 3. تشغيل النفق (Serveo)
echo -e "\e[1;33m[*] TASK 2: Launching Serveo Tunnel...\e[0m"
rm -f "$FLARE_LOG"
nohup flare --port 9002 --tunnel serveo > "$FLARE_LOG" 2>&1 &
sleep 10

TARGET_URL=$(grep -oE 'https://[^ ]+' "$FLARE_LOG" | tail -n 1)
if [ -z "$TARGET_URL" ]; then
    echo -e "\e[1;31m[!] CRITICAL: Failed to extract URL.\e[0m"
    exit 1
fi
echo -e "\e[1;32m[✓] Tunnel Active: $TARGET_URL\e[0m\n"

# 4. المزامنة مع GitHub (النسخة النهائية)
if [ -d "$REPO_DIR/.git" ]; then
    echo -e "\e[1;33m[*] TASK 3: Syncing Final Version to GitHub...\e[0m"
    cd "$REPO_DIR"
    cp "$HOME/final_victory_v27.sh" .
    git add . >/dev/null 2>&1
    git commit -m "Final Victory: V27 Persistent Architecture - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
    echo -e "\e[1;32m[✓] GitHub Sync Complete.\e[0m\n"
fi

# 5. تفعيل الرادار
tmux kill-session -t sentinel_monitor 2>/dev/null
tmux new-session -d -s sentinel_monitor "tail -f $LOG_FILE"

# 6. التوجيهات النهائية
echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] SYSTEM IS NOW IN PERSISTENT MODE.\e[0m"
echo -e "\e[1;33m[!] YOUR TARGET URL: \e[1;37m$TARGET_URL\e[0m\n"
echo -e "\e[1;33m[*] IMPORTANT TEST INSTRUCTION:\e[0m"
echo -e "    Due to ISP Loopback restrictions, you CANNOT test this URL from the same phone/network."
echo -e "    To verify it works:"
echo -e "    1. Turn off Wi-Fi (Use Mobile Data) OR turn off Mobile Data (Use Wi-Fi)."
echo -e "    2. Open the URL above in your browser."
echo -e "    3. You should see a JSON response with your IP."
echo -e "    4. Check the radar to see the captured IP.\n"
echo -e "\e[1;36m[*] To monitor live: \e[1;37mtmux attach -t sentinel_monitor\e[0m"
echo -e "\e[1;36m[*] To stop system: \e[1;37mpkill -9 -f sentinel_core.py; pkill -9 -f flare\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
