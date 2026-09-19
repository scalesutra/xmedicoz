"""
Reverse Proxy Server for XMedicoz Web
- Serves Flutter web build (static files) on /
- Proxies /api/* requests to backend server http://134.195.138.153:5095/api/*
- Solves mixed content (HTTPS ngrok -> HTTP backend) issue
"""
import os
import requests
from flask import Flask, request, Response, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder=None)
CORS(app)

BACKEND_URL = 'http://134.195.138.153:5095'
WEB_DIR = os.path.join(os.path.dirname(__file__), 'build', 'web')

# Proxy all /api/* requests to backend
@app.route('/api/<path:path>', methods=['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'HEAD'])
def proxy_api(path):
    url = f'{BACKEND_URL}/api/{path}'
    
    # Forward headers (except Host)
    headers = {k: v for k, v in request.headers if k.lower() != 'host'}
    
    try:
        resp = requests.request(
            method=request.method,
            url=url,
            headers=headers,
            data=request.get_data(),
            params=request.args,
            timeout=30,
            allow_redirects=False
        )
        
        # Build response excluding hop-by-hop headers
        excluded = {
            'content-encoding',
            'content-length',
            'transfer-encoding',
            'connection',
            'cross-origin-resource-policy',
            'cross-origin-opener-policy',
        }
        response_headers = [(k, v) for k, v in resp.headers.items() if k.lower() not in excluded]
        
        proxy_response = Response(resp.content, resp.status_code, response_headers)
        proxy_response.headers['Cross-Origin-Resource-Policy'] = 'cross-origin'
        proxy_response.headers['X-XMedicoz-Proxy'] = 'local-dev'
        return proxy_response
    except requests.exceptions.RequestException as e:
        return Response(
            f'{{"error": "Backend unreachable: {str(e)}"}}',
            502,
            {'Content-Type': 'application/json'}
        )

# Serve Flutter web static files
@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve_static(path):
    if path and os.path.exists(os.path.join(WEB_DIR, path)):
        return send_from_directory(WEB_DIR, path)
    return send_from_directory(WEB_DIR, 'index.html')

if __name__ == '__main__':
    print('>> XMedicoz Proxy Server')
    print(f'   Static files: {WEB_DIR}')
    print(f'   Backend proxy: {BACKEND_URL}')
    print('   Serving on http://localhost:8088')
    app.run(host='0.0.0.0', port=8088, debug=False)
