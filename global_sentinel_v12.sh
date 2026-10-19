#!/bin/bash
# ==================================================================
# GLOBAL SENTINEL V12 - GITHUB AUTO-SYNC EDITION (alyafee)
# ==================================================================
export DEBIAN_FRONTEND=noninteractive
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
REPO_DIR="$HOME/sentinel-github-repo"
GITHUB_USER="alyafee"
REPO_NAME="sentinel-sovereign-core"
GITHUB_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"

mkdir -p "$API_DIR/logs" "$REPO_DIR"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] INITIATING GLOBAL SENTINEL V12 (AUTO-DEPLOY + GITHUB SYNC)\e[0m"
echo -e "\e[1;36m[!] TARGET GITHUB: $GITHUB_USER\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. تثبيت المتطلبات
echo -e "\e[1;33m[*] 1. Installing Dependencies (Including Git)...\e[0m"
IS_TERMUX=false
if [ -d "/data/data/com.termux" ]; then
    IS_TERMUX=true
    pkg update -y >/dev/null 2>&1
    pkg install -y python nodejs curl tmux cloudflared termux-api git >/dev/null 2>&1
    termux-wake-lock 2>/dev/null
else
    sudo apt-get update -y >/dev/null 2>&1
    sudo apt-get install -y python3 nodejs npm curl tmux git >/dev/null 2>&1
    if ! command -v cloudflared >/dev/null 2>&1; then
        curl -L -o /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb >/dev/null 2>&1
        sudo dpkg -i /tmp/cloudflared.deb >/dev/null 2>&1
    fi
fi
npm install -g localtunnel >/dev/null 2>&1
echo -e "\e[1;32m[✓] Dependencies secured.\e[0m"

# 2. التطهير الشامل
echo -e "\e[1;33m[*] 2. Purging Environment & Patching openurl...\e[0m"
pkill -9 -f "sentinel_core.py" 2>/dev/null
pkill -9 -f "lt --port" 2>/dev/null
pkill -9 -f "cloudflared" 2>/dev/null
sleep 2

if [ "$IS_TERMUX" = true ]; then
    NODE_GLOBAL_MODULES=$(npm root -g 2>/dev/null)
    OPENURL_PATH="$NODE_GLOBAL_MODULES/localtunnel/node_modules/openurl/openurl.js"
    if [ -f "$OPENURL_PATH" ]; then
        cat << 'JS' > "$OPENURL_PATH"
const { exec } = require('child_process');
exports.open = function(url, callback) {
    exec(`command -v termux-open-url`, (err) => {
        if (!err) { exec(`termux-open-url "${url}"`, callback); }
        else { exec(`xdg-open "${url}"`, callback); }
    });
};
JS
    fi
fi

# 3. تحديد منفذ حر ديناميكياً (تجنب المنفذ 3000 المحجوز)
PORT=9000
for p in 9000 9001 9002 9003 9004; do
    if python3 -c "import socket; s=socket.socket(); s.bind(('127.0.0.1', $p)); s.close()" 2>/dev/null; then
        PORT=$p
        break
    fi
done
echo -e "\e[1;32m[✓] Secured free port: $PORT (Port 3000 is untouched).\e[0m"

# 4. بناء النواة
echo -e "\e[1;33m[*] 3. Building Sovereign Core...\e[0m"
cat << PY > "$API_DIR/sentinel_core.py"
import http.server, json, sys
from datetime import datetime
PORT = $PORT
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            ip = self.headers.get('X-Forwarded-For', self.client_address[0])
            data = json.dumps({"status": "SECURE_ACK", "real_ip": ip, "time": datetime.now().isoformat()}).encode()
            self.send_response(200); self.send_header("Content-Type", "application/json"); self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data)
            print(f"[+] CAPTURED TARGET IP: {ip} | TIME: {datetime.now().isoformat()}", flush=True)
        except Exception: pass
    def log_message(self, fmt, *args): pass
http.server.HTTPServer.allow_reuse_address = True
with http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler) as httpd:
    httpd.serve_forever()
PY

nohup python3 -u "$API_DIR/sentinel_core.py" > "$LOG_FILE" 2>&1 &
sleep 2

# 5. إطلاق النفق
echo -e "\e[1;33m[*] 4. Launching Tunnel...\e[0m"
rm -f "$API_DIR/logs/lt.log" "$API_DIR/logs/cf.log"
nohup bash -c "while true; do lt --port $PORT --host http://loca.lt --local-host 127.0.0.1 >> \"$API_DIR/logs/lt.log\" 2>&1; sleep 5; done" > /dev/null 2>&1 &
sleep 6

LT_URL=$(grep -o 'https://[^ ]*\.loca\.lt' "$API_DIR/logs/lt.log" | head -n 1)

if [ -n "$LT_URL" ]; then
    TARGET_URL=$LT_URL
    echo -e "\e[1;32m[✓] LocalTunnel Active.\e[0m"
else
    echo -e "\e[1;31m[-] LocalTunnel failed. Executing Cloudflared...\e[0m"
    pkill -9 -f "lt --port" 2>/dev/null
    nohup cloudflared tunnel --no-autoupdate --protocol http2 --url http://127.0.0.1:$PORT > "$API_DIR/logs/cf.log" 2>&1 &
    sleep 6
    TARGET_URL=$(grep -o 'https://[^ ]*\.trycloudflare\.com' "$API_DIR/logs/cf.log" | head -n 1)
    if [ -z "$TARGET_URL" ]; then
        echo -e "\e[1;31m[!] CRITICAL: Both tunnels failed. Check internet.\e[0m"
        exit 1
    fi
    echo -e "\e[1;32m[✓] Cloudflared Active.\e[0m"
fi

# 6. الاختبار الحقيقي
echo -e "\e[1;33m[*] 5. Executing Real-World Capture Test...\e[0m"
RESPONSE=$(curl -s -m 10 -H "Bypass-Tunnel-Reminder: true" "$TARGET_URL")
echo -e "\e[1;36m[+] Server Response: \e[1;37m$RESPONSE\e[0m\n"

# 7. المزامنة التلقائية مع GitHub (alyafee)
echo -e "\e[1;33m[*] 6. Executing Auto-GitHub Sync to: $GITHUB_URL\e[0m"
cp "$HOME/global_sentinel_v12.sh" "$REPO_DIR/" 2>/dev/null
cp "$API_DIR/sentinel_core.py" "$REPO_DIR/" 2>/dev/null
cd "$REPO_DIR"

if [ ! -d ".git" ]; then
    git init >/dev/null 2>&1
    git remote add origin "$GITHUB_URL" >/dev/null 2>&1
fi

# ضبط بيانات المؤلف
git config user.name "$GITHUB_USER" >/dev/null 2>&1
git config user.email "$GITHUB_USER@users.noreply.github.com" >/dev/null 2>&1

git add . >/dev/null 2>&1
git commit -m "Auto-Deploy: Sentinel V12 Update - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
git branch -M main >/dev/null 2>&1

# محاولة الرفع
echo -e "\e[1;36m[*] Attempting to push to GitHub (If it hangs, you need to enter your PAT)...\e[0m"
if git push -u origin main >/dev/null 2>&1; then
    echo -e "\e[1;32m[✓] SUCCESS! System uploaded to GitHub successfully.\e[0m"
else
    echo -e "\e[1;33m[!] GITHUB AUTH REQUIRED.\e[0m"
    echo -e "\e[1;37m    Your code is saved locally at: $REPO_DIR\e[0m"
    echo -e "\e[1;37m    To push manually, run: cd $REPO_DIR && git push -u origin main\e[0m"
    echo -e "\e[1;37m    (Use your Personal Access Token as the password when prompted).\e[0m"
fi
echo -e "\n"

# 8. المراقبة وتسليم الرابط
if command -v tmux >/dev/null 2>&1; then
    tmux kill-session -t sentinel_monitor 2>/dev/null
    tmux new-session -d -s sentinel_monitor "tail -f $LOG_FILE"
fi

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] SYSTEM IS LIVE AND PERSISTENT\e[0m"
echo -e "\e[1;33m[!] YOUR PERMANENT URL: \e[1;37m$TARGET_URL\e[0m"
echo -e "\e[1;36m[*] To monitor live: \e[1;37mtmux attach -t sentinel_monitor\e[0m"
echo -e "\e[1;36m[*] To stop: \e[1;37mpkill -9 -f sentinel_core.py; pkill -9 -f lt; pkill -9 -f cloudflared\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
