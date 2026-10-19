#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
CF_LOG="$API_DIR/logs/cf_ubuntu.log"
mkdir -p "$API_DIR/logs"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] INITIATING UBUNTU NATIVE BYPASS (V43)\e[0m"
echo -e "\e[1;36m[!] USING UBUNTU PROOT TO BYPASS ANDROID KERNEL LIMITS\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. التطهير الشامل
echo -e "\e[1;33m[*] TASK 1: Purging Environment...\e[0m"
pkill -9 -f "sentinel_core.py" 2>/dev/null
pkill -9 -f "cloudflared" 2>/dev/null
pkill -9 -f "ssh.*serveo" 2>/dev/null
sleep 2
> "$LOG_FILE"
> "$CF_LOG"

# 2. تشغيل النواة السيادية (في Termux)
echo -e "\e[1;33m[*] TASK 2: Starting Core Engine (Port 9002)...\e[0m"
termux-wake-lock 2>/dev/null
nohup stdbuf -oL -eL python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
sleep 2

# 3. التحقق من وجود Ubuntu proot
if ! command -v proot-distro &> /dev/null; then
    echo -e "\e[1;31m[!] CRITICAL: proot-distro not found. Please install Ubuntu first.\e[0m"
    exit 1
fi

# 4. تشغيل النفق من داخل Ubuntu
echo -e "\e[1;33m[*] TASK 3: Launching Tunnel from inside Ubuntu...\e[0m"
# نقوم بتشغيل أوامر داخل Ubuntu لتثبيت وتشغيل cloudflared
# ملاحظة: نستخدم http2 لتجاوز حظر UDP
PROOT_CMD="
    if ! command -v cloudflared &> /dev/null; then
        echo 'Installing cloudflared inside Ubuntu...'
        curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /usr/local/bin/cloudflared
        chmod +x /usr/local/bin/cloudflared
    fi
    cloudflared tunnel --no-autoupdate --protocol http2 --url http://127.0.0.1:9002
"

# تشغيل Ubuntu في الخلفية وتوجيه المخرجات إلى السجل
nohup proot-distro login ubuntu -- bash -c "$PROOT_CMD" > "$CF_LOG" 2>&1 &
sleep 12 # انتظار تشغيل النفق واستقراره

# 5. استخراج الرابط من سجل Ubuntu
TARGET_URL=$(grep -oE 'https://[^ ]*\.trycloudflare\.com' "$CF_LOG" | head -n 1)
if [ -z "$TARGET_URL" ]; then
    echo -e "\e[1;31m[!] CRITICAL: Cloudflared inside Ubuntu failed.\e[0m"
    echo -e "\e[1;33m[*] Log details:\e[0m"
    tail -n 10 "$CF_LOG"
    exit 1
fi
echo -e "\e[1;32m[✓] Tunnel Active via Ubuntu: $TARGET_URL\e[0m\n"

# 6. الاختراق الذاتي (Self-Strike)
echo -e "\e[1;33m[*] TASK 4: Executing Autonomous Browser Strike...\e[0m"
termux-open-url "$TARGET_URL" &
sleep 8

# 7. سحب الدليل
echo -e "\e[1;32m[✓] PROOF OF CAPTURE (From Core Engine Log):\e[0m"
echo -e "\e[1;37m-------------------------------------------------\e[0m"
if [ -s "$LOG_FILE" ]; then
    cat "$LOG_FILE"
    echo -e "\e[1;37m-------------------------------------------------\e[0m"
    echo -e "\e[1;32m[!] SUCCESS: Ubuntu bypassed Android limitations! IP captured.\e[0m"
else
    echo -e "\e[1;31m[-] No IP captured. The request might be delayed.\e[0m"
    echo -e "\e[1;33m[*] Check manually: open $TARGET_URL in your browser.\e[0m"
fi

# 8. المزامنة
if [ -d "$HOME/sentinel-github-repo/.git" ]; then
    cd "$HOME/sentinel-github-repo"
    cp "$HOME/ubuntu_tunnel_v43.sh" .
    git add . >/dev/null 2>&1
    git commit -m "Auto-Update: V43 Ubuntu Native Bypass - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
fi

echo -e "\n\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] MISSION COMPLETE. CHECK RESULTS ABOVE.\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
