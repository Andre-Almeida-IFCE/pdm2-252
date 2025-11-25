from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        qs = parse_qs(parsed.query)
        code = qs.get('code', [''])[0]
        # Respond with a simple HTML page showing the code and instructions
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()
        body = f"""
<html>
  <head><title>OAuth Code Captured</title></head>
  <body>
    <h2>GitHub Authorization Code</h2>
    <p>Copy the value below and paste it into your Flutter app dialog.</p>
    <pre style="background:#f4f4f4;padding:10px;border-radius:6px;">{code}</pre>
    <p>Full request path: <code>{self.path}</code></p>
    <p>You can close this page after copying the code.</p>
  </body>
</html>
"""
        self.wfile.write(body.encode('utf-8'))

        # Also print to console for convenience
        print('--- Incoming request ---')
        print('Path:', self.path)
        print('Code:', code)
        print('-------------------------')

if __name__ == '__main__':
    host = 'localhost'
    port = 5000
    server = HTTPServer((host, port), Handler)
    print(f"Listening on http://{host}:{port}/auth")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()
    print('Server stopped')
