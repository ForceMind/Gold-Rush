import http.server
import ssl
import os

PORT = 8060
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dist")
BASE = os.path.dirname(os.path.abspath(__file__))


class GodotHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def guess_type(self, path):
        mime = super().guess_type(path)
        if path.endswith(".wasm"):
            return "application/wasm"
        if path.endswith(".pck"):
            return "application/octet-stream"
        return mime


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", PORT), GodotHandler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(os.path.join(BASE, "server.crt"), os.path.join(BASE, "server.key"))
    server.socket = ctx.wrap_socket(server.socket, server_side=True)
    print(f"黄金冲刺 已启动 (HTTPS)")
    print(f"本机:   https://localhost:{PORT}")
    print(f"局域网: https://192.168.50.129:{PORT}")
    server.serve_forever()
