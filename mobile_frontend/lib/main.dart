import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: UltraShareApp()));
}

class UltraShareApp extends StatelessWidget {
  const UltraShareApp({super.key});

  Future<void> launchRustEngine() async {
    try {
      // Unpack the optimized binary from the app assets out onto the file system storage
      final byteData = await rootBundle.load('assets/bin/ultra_share');
      final file = File('${Directory.systemTemp.path}/ultra_share');
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      
      // Grant executable launch permissions to the Linux kernel sub-system
      await Process.run('chmod', ['+x', file.path]);
      
      // Fire up our lightning fast engine sockets in background mode!
      await Process.start(file.path, ['receive', '8080']);
      print("UltraShare Engine is actively running!");
    } catch (e) {
      print("Failed to launch background engine: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UltraShare Mobile')),
      body: Center(
        child: ElevatedButton(
          onPressed: launchRustEngine,
          child: const Text('Initialize High-Speed Storage Engine'),
        ),
      ),
    );
  }
}
