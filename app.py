from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Olá, DevSecOps Lab!"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
