#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
FLARE_LOG="$API_DIR/logs/flare.log"
mkdir -p "$API_DIR/logs"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] INITIATING SURGICAL STRIKE V25 (FORCED CAPTURE)\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. تطهير سريع
pkill -9 -f "sentinel_core.py" 2>/dev/null
pkill -9 -f "flare" 2>/dev/null
sleep 2

# 2. تشغيل النواة
echo -e "\e[1;33m[*] TASK 1: Starting Smart Core...\e[0m"
nohup stdbuf -oL -eL python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
sleep 2

# 3. تشغيل Serveo
echo -e "\e[1;33m[*] TASK 2: Launching Serveo Tunnel...\e[0m"
rm -f "$FLARE_LOG"
nohup flare --port 9002 --tunnel serveo > "$FLARE_LOG" 2>&1 &
# انتظار أطول لضمان استقرار الاتصال عبر الشبكات المقيدة
sleep 12

TARGET_URL=$(grep -oE 'https://[^ ]+' "$FLARE_LOG" | tail -n 1)
if [ -z "$TARGET_URL" ]; then
    echo -e "\e[1;31m[!] CRITICAL: Failed to extract URL.\e[0m"
    exit 1
fi
echo -e "\e[1;32m[✓] Tunnel Active: $TARGET_URL\e[0m\n"

# 4. الضربة الجراحية (3 محاولات بـ User-Agent حقيقي)
echo -e "\e[1;33m[*] TASK 3: Executing Surgical Strike (3 Attempts)...\e[0m"
for i in 1 2 3; do
    echo -e "    Attempt $i: Sending payload..."
    # -L: تتبع التحويلات، -A: محاكاة متصفح، -H: تجاوز الحماية
    curl -s -L -m 15 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -H "Bypass-Tunnel-Reminder: true" "$TARGET_URL" > /dev/null
    sleep 3
done

# 5. سحب الدليل (Dump Logs)
echo -e "\n\e[1;32m[✓] PROOF OF CAPTURE (Full Core Log Dump):\e[0m"
echo -e "\e[1;37m-------------------------------------------------\e[0m"
# طباعة السجل بالكامل لضمان رؤية أي نشاط
cat "$LOG_FILE"
echo -e "\e[1;37m-------------------------------------------------\e[0m\n"

# 6. المزامنة مع GitHub
if [ -d "$HOME/sentinel-github-repo/.git" ]; then
    cd "$HOME/sentinel-github-repo"
    cp "$HOME/surgical_strike_v25.sh" .
    git add . >/dev/null 2>&1
    git commit -m "Auto-Update: V25 Surgical Strike - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
    echo -e "\e[1;32m[✓] GitHub Sync Complete.\e[0m\n"
fi

# 7. تفعيل الرادار
tmux kill-session -t sentinel_monitor 2>/dev/null
tmux new-session -d -s sentinel_monitor "tail -f $LOG_FILE"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] MISSION ACCOMPLISHED.\e[0m"
echo -e "\e[1;33m[!] YOUR URL: \e[1;37m$TARGET_URL\e[0m"
echo -e "\e[1;36m[*] To monitor live: \e[1;37mtmux attach -t sentinel_monitor\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
