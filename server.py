from flask import Flask
from flask_socketio import SocketIO
import pyperclip
import threading
import time

# Step 1: Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'

# Step 2: Initialize WebSocket (SocketIO) server
# 'eventlet' is async engine; it lets Flask handle real-time sockets efficiently
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# Step 3: Track the last copied clipboard text on Mac
last_clipboard_text = ""
@app.route('/')
def index():
    return "Flask WebSocket Server is running!"
# Step 4: Listen to changes from the Android app
@socketio.on('clipboard_from_android')
def handle_android_clipboard(data):
    global last_clipboard_text
    print("[Android] Sent clipboard:", data)

    # Prevent re-copying the same text
    if data != last_clipboard_text:
        pyperclip.copy(data)  # Set to Mac clipboard
        last_clipboard_text = data

# Step 5: Run the server
if __name__ == '__main__':
    print("🖥️ Flask WebSocket Server running on ws://<your-mac-ip>:5050")
    socketio.run(app,host='0.0.0.0',port=5050)