#there is app.py
from flask import Flask, make_response

app = Flask(__name__)

@app.route('/')
def hello():
    return "Olá, DevSecOps Lab!"

def add_security_headers(response):
    response.headers['Content-Security-Policy'] = "default-src 'self'; frame-ancestors 'self'; form-action 'self';"
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['Cross-Origin-Resource-Policy'] = 'same-origin'
    response.headers['Cross-Origin-Embedder-Policy'] = 'require-corp'
    response.headers['Cross-Origin-Opener-Policy'] = 'same-origin'
    response.headers['Permissions-Policy'] = "camera=(), microphone=(), geolocation=(), fullscreen=()"
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

@app.after_request
def after_request(response):
    return add_security_headers(response)

if __name__ == '__main__':
    from waitress import serve
    serve(app, host='127.0.0.1', port=5000)
