#there is app.py
from flask import Flask, make_response

app = Flask(__name__)

@app.route('/')
def hello():
    return "Olá, DevSecOps Lab!"

def add_security_headers(response):
    response.headers['Content-Security-Policy'] = "default-src 'self';"
    return(response)

@app.after_request
def after_request(response):
    return add_security_headers(response)

if __name__ == '__main__':
    app.run(debug=False, host='127.0.0.1')
