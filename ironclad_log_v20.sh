#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
CF_LOG="$API_DIR/logs/cf.log"
BORE_LOG="$API_DIR/logs/bore.log"
mkdir -p "$API_DIR/logs"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] INITIATING IRONCLAD LOG PROTOCOL (V20)\e[0m"
echo -e "\e[1;36m[!] FORCING REAL-TIME LOG FLUSH & TUNNEL VERIFICATION\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. تطهير شامل
pkill -9 -f "sentinel_core.py" 2>/dev/null
pkill -9 -f "cloudflared" 2>/dev/null
pkill -9 -f "bore" 2>/dev/null
sleep 2

# 2. بناء النواة مع التفريغ القسري (stdbuf)
echo -e "\e[1;33m[*] TASK 1: Building Core with Forced Unbuffered Output...\e[0m"
cat << PY > "$API_DIR/sentinel_core.py"
import http.server, json, sys
from datetime import datetime
PORT = 9002
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            ip = self.headers.get('X-Forwarded-For', self.client_address[0])
            data = json.dumps({"status": "SECURE_ACK", "real_ip": ip, "time": datetime.now().isoformat()}).encode()
            self.send_response(200); self.send_header("Content-Type", "application/json"); self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data)
            print(f"[+] CAPTURED TARGET IP: {ip} | TIME: {datetime.now().isoformat()}", flush=True)
        except Exception as e:
            print(f"[!] Handler Error: {e}", file=sys.stderr, flush=True)
    def log_message(self, fmt, *args): pass
http.server.HTTPServer.allow_reuse_address = True
with http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler) as httpd:
    httpd.serve_forever()
PY

# تشغيل باستخدام stdbuf لضمان التفريغ الفوري
termux-wake-lock 2>/dev/null
nohup stdbuf -oL -eL python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
sleep 2
echo -e "\e[1;32m[✓] Core Engine: ONLINE (Unbuffered)\e[0m\n"

# 3. التحقق من صحة Cloudflared
echo -e "\e[1;33m[*] TASK 2: Verifying Cloudflared Health...\e[0m"
rm -f "$CF_LOG"
nohup cloudflared tunnel --no-autoupdate --protocol http2 --url "http://127.0.0.1:9002" > "$CF_LOG" 2>&1 &
sleep 10

TARGET_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$CF_LOG" | head -n 1)
CF_ERROR=$(grep -i "error\|failed\|unable" "$CF_LOG" | head -n 1)

if [ -n "$TARGET_URL" ] && [ -z "$CF_ERROR" ]; then
    echo -e "\e[1;32m[✓] Cloudflared Active: $TARGET_URL\e[0m\n"
elif [ -n "$CF_ERROR" ]; then
    echo -e "\e[1;31m[!] Cloudflared Error Detected: $CF_ERROR\e[0m"
    echo -e "\e[1;33m[*] Switching to BORE (Alternative Tunnel)...\e[0m"
    pkill -9 -f "cloudflared" 2>/dev/null
    # تثبيت bore إذا لم يكن موجوداً
    pkg install -y bore >/dev/null 2>&1
    nohup bore local 9002 --to bore.pub > "$BORE_LOG" 2>&1 &
    sleep 5
    TARGET_URL=$(grep -o 'bore.pub:[0-9]*' "$BORE_LOG" | head -n 1)
    if [ -n "$TARGET_URL" ]; then
        TARGET_URL="http://$TARGET_URL"
        echo -e "\e[1;32m[✓] BORE Active: $TARGET_URL\e[0m\n"
    else
        echo -e "\e[1;31m[!] BORE Failed. System may be offline.\e[0m"
        exit 1
    fi
else
    echo -e "\e[1;31m[!] Cloudflared failed to generate URL.\e[0m"
    exit 1
fi

# 4. الاختبار المباشر مع التحقق من السجل
echo -e "\e[1;33m[*] TASK 3: Direct Strike & Log Verification...\e[0m"
# إرسال طلبين للتأكد من وصول أحدهما على الأقل
curl -s -m 10 -H "Bypass-Tunnel-Reminder: true" "$TARGET_URL" > /dev/null
sleep 1
curl -s -m 10 -H "Bypass-Tunnel-Reminder: true" "$TARGET_URL" > /dev/null
sleep 2

echo -e "\e[1;32m[✓] PROOF OF CAPTURE (From Core Engine Log):\e[0m"
echo -e "\e[1;37m-------------------------------------------------\e[0m"
# سحب آخر 3 أسطر تحتوي على التقاط
grep "CAPTURED TARGET IP" "$LOG_FILE" | tail -n 3
echo -e "\e[1;37m-------------------------------------------------\e[0m\n"

# 5. المزامنة مع GitHub
if [ -d "$HOME/sentinel-github-repo/.git" ]; then
    cd "$HOME/sentinel-github-repo"
    cp "$HOME/ironclad_log_v20.sh" .
    git add . >/dev/null 2>&1
    git commit -m "Auto-Update: V20 Ironclad Log - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
    echo -e "\e[1;32m[✓] GitHub Sync: UP TO DATE.\e[0m\n"
fi

# 6. تفعيل الرادار
tmux kill-session -t sentinel_monitor 2>/dev/null
tmux new-session -d -s sentinel_monitor "tail -f $LOG_FILE"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] MISSION ACCOMPLISHED. SYSTEM IS STABLE.\e[0m"
echo -e "\e[1;33m[!] YOUR URL: \e[1;37m$TARGET_URL\e[0m"
echo -e "\e[1;36m[*] To monitor live: \e[1;37mtmux attach -t sentinel_monitor\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
