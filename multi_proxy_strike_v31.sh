#!/data/data/com.termux/files/usr/bin/bash
API_DIR="$HOME/.sentinel-api"
LOG_FILE="$API_DIR/logs/core.log"
FLARE_LOG="$API_DIR/logs/flare.log"

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;36m[!] INITIATING MULTI-PROXY STRIKE (V31)\e[0m"
echo -e "\e[1;36m[!] USING 3 ROBUST EXTERNAL PROXIES\e[0m"
echo -e "\e[1;36m=================================================================\e[0m\n"

# 1. استخراج الرابط
TARGET_URL=$(grep -oE 'https://[^ ]+' "$FLARE_LOG" | tail -n 1)
if [ -z "$TARGET_URL" ]; then
    echo -e "\e[1;31m[!] CRITICAL: No active URL found.\e[0m"
    exit 1
fi
echo -e "\e[1;33m[*] Target URL: \e[1;37m$TARGET_URL\e[0m\n"

# 2. تنظيف السجل لرؤية الالتقاطات الجديدة فقط
> "$LOG_FILE"
echo -e "\e[1;33m[*] Logs cleared. Sending strikes from 3 different proxy nodes...\e[0m"

# 3. المحاولة الأولى: CORS Proxy
echo -e "    [1/3] Strike via corsproxy.io..."
curl -s -m 10 "https://corsproxy.io/?${TARGET_URL}" > /dev/null

# 4. المحاولة الثانية: CodeTabs Proxy
echo -e "    [2/3] Strike via api.codetabs.com..."
curl -s -m 10 "https://api.codetabs.com/v1/proxy?quest=${TARGET_URL}" > /dev/null

# 5. المحاولة الثالثة: Jina AI Reader (وكيل قوي جداً يتجاوز الحمايات)
echo -e "    [3/3] Strike via r.jina.ai..."
curl -s -m 10 "https://r.jina.ai/${TARGET_URL}" > /dev/null

echo -e "\n\e[1;33m[*] Waiting 5 seconds for external nodes to reach your server...\e[0m"
sleep 5

# 6. سحب الدليل
echo -e "\n\e[1;32m[✓] PROOF OF CAPTURE (From Core Engine Log):\e[0m"
echo -e "\e[1;37m-------------------------------------------------\e[0m"
cat "$LOG_FILE"
echo -e "\e[1;37m-------------------------------------------------\e[0m\n"

# 7. تقرير الحالة
if grep -q "CAPTURED TARGET IP" "$LOG_FILE"; then
    echo -e "\e[1;32m[!] SUCCESS: The external proxies successfully hit your server! (IPs are logged above).\e[0m"
else
    echo -e "\e[1;33m[!] WARNING: Serveo's WAF is blocking all known automated proxies.\e[0m"
    echo -e "\e[1;33m[*] To test manually: Switch network (4G/Wi-Fi) and open the URL in your browser.\e[0m"
fi

# 8. المزامنة مع GitHub
if [ -d "$HOME/sentinel-github-repo/.git" ]; then
    cd "$HOME/sentinel-github-repo"
    cp "$HOME/multi_proxy_strike_v31.sh" .
    git add . >/dev/null 2>&1
    git commit -m "Auto-Update: V31 Multi-Proxy Strike - $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1
    git push origin main >/dev/null 2>&1
fi

echo -e "\e[1;36m=================================================================\e[0m"
echo -e "\e[1;32m[!] MISSION COMPLETE. SYSTEM IS STABLE.\e[0m"
echo -e "\e[1;33m[!] YOUR TARGET URL: \e[1;37m$TARGET_URL\e[0m"
echo -e "\e[1;36m=================================================================\e[0m"
