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
  Timer? clipboardTriggerTimer;
  late IO.Socket socket;
  String clipdata = "";
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
  }

  void startClipboardMonitor() {
    print('📋 Clipboard monitor running...');
    clipboardTriggerTimer = Timer.periodic(const Duration(seconds: 2), (
      _,
    ) async {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text != null && clipboardData!.text != clipdata) {
        clipdata = clipboardData.text!;
        socket.emit('clipboard_from_android', clipdata);
        print("📤 Sent to server: $clipdata");
      }
    });
  }

  void copyToClipboard(String message) async {
    await Clipboard.setData(ClipboardData(text: message));
    print("📋 Copied to clipboard: $message");
  }

  void connectt() {
    socket = IO.io(
      'http://{yourIp}:5050',
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print('🔌 Connected to server');
      socket.emit('clipboard_from_android', "start...");
      setState(() => isConnected = true);

      socket.on('clipboard_from_mac', (data) {
        print("📥 Received from server: $data");
        copyToClipboard(data);
      });

      startClipboardMonitor();
    });
  }

  void disconnectt() {
    clipboardTriggerTimer?.cancel();
    print('🔌 Disconnected from server');
    socket.emit('clipboard_from_android', "stop...");
    Future.delayed(const Duration(seconds: 1), () {
      socket.disconnect();
      setState(() => isConnected = false);
    });
  }

  @override
  void dispose() {
    clipboardTriggerTimer?.cancel();
    clipboardContentStream.close();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Clipboard Sync',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: GestureDetector(
          onTap: isConnected ? disconnectt : connectt,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isConnected ? Colors.blue : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.sync,
              color: isConnected ? Colors.white : Colors.blueGrey,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
