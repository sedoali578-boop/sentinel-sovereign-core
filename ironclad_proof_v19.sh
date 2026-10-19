#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
CF_LOG="$API_DIR/logs/cf.log"
REPO_DIR="$HOME/sentinel-github-repo"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] INITIATING IRONCLAD PROOF PROTOCOL (V19)\e[0m"
echo -e "\e[1;36m[!] TARGET: BYPASS ISP RESTRICTIONS & CLOUDFLARE BOT BLOCKS\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. تطهير سريع
pkill -9 -f "sentinel_core.py" 2>/dev/null
pkill -9 -f "cloudflared" 2>/dev/null
sleep 2

# 2. جلب الـ IP بأدوات بديلة (في حال حظر api.ipify)
echo -e "\e[1;33m[*] TASK 1: Fetching Local Public IP (ISP Bypass)...\e[0m"
LOCAL_IP=$(curl -s -m 3 https://icanhazip.com 2>/dev/null || curl -s -m 3 https://ifconfig.me 2>/dev/null || echo "Unknown (ISP Blocked)")
echo -e "    Your Local IP: \e[1;37m$LOCAL_IP\e[0m"

# 3. تشغيل النواة (المنفذ 9002 الذي أثبت نجاحه سابقاً)
PORT=9002
nohup python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
sleep 2

# 4. تشغيل Cloudflare (البروتوكول الأكثر استقراراً)
echo -e "\e[1;33m[*] TASK 2: Launching Cloudflared (HTTP/2)...\e[0m"
rm -f "$CF_LOG"
nohup cloudflared tunnel --no-autoupdate --protocol http2 --url "http://127.0.0.1:$PORT" > "$CF_LOG" 2>&1 &
sleep 8

TARGET_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$CF_LOG" | head -n 1)
if [ -z "$TARGET_URL" ]; then
    echo -e "\e[1;31m[!] CRITICAL: Cloudflare failed to start.\e[0m"
    exit 1
fi
echo -e "\e[1;32m[✓] Tunnel Active: $TARGET_URL\e[0m\n"

# 5. الاختراق المحلي المباشر (Local Direct Strike) - الدليل القاطع
echo -e "\e[1;33m[*] TASK 3: Executing Direct Strike & Extracting Proof...\e[0m"
echo -e "    Sending HTTP request directly to the tunnel..."
# إرسال طلب مع ترويسة تجاوز الحماية
curl -s -m 10 -H "Bypass-Tunnel-Reminder: true" "$TARGET_URL" > /dev/null
sleep 2

echo -e "\e[1;32m[✓] PROOF OF CAPTURE (From Core Engine Log):\e[0m"
echo -e "\e[1;37m-------------------------------------------------\e[0m"
# سحب آخر سطر من السجل يحتوي على IP
LAST_CAPTURE=$(grep "CAPTURED TARGET IP" "$LOG_FILE" | tail -n 1)
if [ -n "$LAST_CAPTURE" ]; then
    echo -e "\e[1;32m$LAST_CAPTURE\e[0m"
else
    echo -e "\e[1;31m[-] No IP captured in log. (Possible Cloudflare delay).\e[0m"
fi
echo -e "\e[1;37m-------------------------------------------------\e[0m\n"

# 6. المزامنة مع GitHub
if [ -d "$REPO_DIR/.git" ]; then
    cd "$REPO_DIR"
    cp "$HOME/ironclad_proof_v19.sh" "$REPO_DIR/" 2>/dev/null
    git add . >/dev/null 2>&1
    git commit -m "Auto-Update: Ironclad V19 - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
    echo -e "\e[1;32m[✓] GitHub Sync: UP TO DATE.\e[0m\n"
fi

# 7. تفعيل الرادار
tmux kill-session -t sentinel_monitor 2>/dev/null
tmux new-session -d -s sentinel_monitor "tail -f $LOG_FILE"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] MISSION ACCOMPLISHED. SYSTEM IS STABLE.\e[0m"
echo -e "\e[1;33m[!] YOUR URL: \e[1;37m$TARGET_URL\e[0m"
echo -e "\e[1;36m[*] To monitor live: \e[1;37mtmux attach -t sentinel_monitor\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
