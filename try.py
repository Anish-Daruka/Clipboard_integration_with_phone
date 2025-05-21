import socketio

sio = socketio.Client()


def send_data():
    while True:
       s=input()
       sio.emit('clipboard_from_android', s)

@sio.event
def connect():
    print("Connected to server")
    # sio.emit('clipboard_from_android', 'Hello from clien!')

sio.connect('http://Anishs-MacBook-Air-5.local:5050')
send_data()
