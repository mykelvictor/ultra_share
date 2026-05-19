import 'package:flutter/material.dart';
import 'screens/qr_scanner_screen.dart';

void main() {
  runApp(const UltraShareApp());
}

class UltraShareApp extends StatelessWidget {
  const UltraShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🚀 UltraShare Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        message: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.bolt, size: 80, color: Colors.amber),
            SizedBox(height: 10),
            Text(
              '11Gbps+ Raw Streaming Protocol',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: null, // Placeholder for generating receiver QR code
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: Text('Receive Folder (Show QR)'),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QrScannerScreen(folderToStream: "/storage/emulated/0/Download"),
                  ),
                );
              },
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: Text('Scan QR Code to Send Folder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
