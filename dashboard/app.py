from flask import Flask, render_template, request, session
import sqlite3
import json

app = Flask(__name__)
app.secret_key = 'vpsik_secret'

def check_login(user, passw):
    config = json.load(open('/opt/VPSIk-Alert/config/config.json'))
    return user == config['dashboard']['user'] and passw == config['dashboard']['pass']

@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        if check_login(request.form['user'], request.form['pass']):
            session['logged_in'] = True
            return render_template('index.html')
    return render_template('login.html')

@app.route('/dashboard')
def dashboard():
    if not session.get('logged_in'):
        return redirect('/')
    conn = sqlite3.connect('/opt/VPSIk-Alert/database/metrics.db')
    data = conn.execute('SELECT * FROM metrics ORDER BY timestamp DESC LIMIT 24').fetchall()
    conn.close()
    return render_template('charts.html', data=data)

if __name__ == '__main__':
    port = json.load(open('/opt/VPSIk-Alert/config/config.json'))['dashboard']['port']
    app.run(host='0.0.0.0', port=port, debug=False)
