from flask import Flask
from flask_socketio import SocketIO
import pyperclip
import threading
import time
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = 'secret!'

socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

last_clipboard_text = ""
flag = False
lock = threading.Lock()


@app.route('/')
def index():
    return "Flask WebSocket Server is running!"


def clipboard_monitor():
    global last_clipboard_text
    try:
        current_text = pyperclip.paste()
        if current_text != last_clipboard_text:
            last_clipboard_text = current_text
            print("📤 Sending clipboard:", current_text)
            socketio.emit('clipboard_from_mac', current_text)
    except Exception as e:
        print("⚠️ Clipboard monitor error:", e)
    time.sleep(2)

@socketio.on('clipboard_from_mac')
def testing(data):
    print("received from mac",data)


@socketio.on('clipboard_from_android')
def handle_android_clipboard(data):
    global last_clipboard_text, flag
    print("📥 [Android] Sent clipboard:", data)

    if data == "stop...":
        with lock:
            flag = False
        return

    if data == "start...":
        with lock:
            if not flag:
                flag = True
                start_clipboard_thread()
        return

    if data != last_clipboard_text:
        pyperclip.copy(data)
        last_clipboard_text = data


def start_clipboard_thread():
    thread = threading.Thread(target=clipboard_monitor_loop, daemon=True)
    thread.start()


def clipboard_monitor_loop():
    global flag
    while True:
        with lock:
            if not flag:
                break
        clipboard_monitor()


if __name__ == '__main__':
    print("🖥️ Flask WebSocket Server running on ws://<your-mac-ip>:5050")
    socketio.run(app, host='0.0.0.0', port=5050)