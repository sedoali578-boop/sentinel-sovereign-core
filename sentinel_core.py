import http.server, json, sys
from datetime import datetime
PORT = 9003
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
