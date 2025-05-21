import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ClipboardMonitor(),
    );
  }
}

class ClipboardMonitor extends StatefulWidget {
  const ClipboardMonitor({super.key});

  @override
  State<ClipboardMonitor> createState() => _ClipboardMonitorState();
}

class _ClipboardMonitorState extends State<ClipboardMonitor> {
  final StreamController<String> clipboardContentStream =
      StreamController<String>.broadcast();
  late Timer clipboardTriggerTimer;
  late IO.Socket socket;
  var clipdata = "";

  @override
  void initState() {
    super.initState();
    connectt();
  }

  void startClipboardMonitor() {
    clipboardTriggerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      Clipboard.getData('text/plain').then((clipboardData) {
        if (clipboardData != null &&
            clipboardData.text != null &&
            clipdata != clipboardData.text) {
          clipdata = clipboardData.text!;

          socket.emit('clipboard_from_android', clipdata);
          print("📤 Sent to server: $clipdata");
        }
      });
    });
  }

  void copyToClipboard(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    print("📋 Copied to clipboard: $message");
  }

  void connectt() {
    print("here1");

    socket = IO.io(
      'http://Anishs-MacBook-Air-5.local:5050',
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );
    print("here");

    socket.connect();

    socket.onConnect((_) {
      print('✅ Socket connected');
    });

    socket.onDisconnect((_) {
      print('❌ Socket disconnected');
    });

    startClipboardMonitor();
  }

  @override
  void dispose() {
    clipboardTriggerTimer.cancel();
    clipboardContentStream.close();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clipboard Monitor')),
      body: Center(child: Text((clipdata == '') ? 'No data' : clipdata)),
    );
  }
}
