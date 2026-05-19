import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class QrScannerScreen extends StatefulWidget {
  final String folderToStream;
  const QrScannerScreen({Key? key, required this.folderToStream}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  static const platformEngine = MethodChannel('com.mykelvictor.ultrashare/engine');
  bool isScanningCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receiver QR Code')),
      body: MobileScanner(
        onDetect: (capture) async {
          if (isScanningCompleted) return;
          
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            setState(() { isScanningCompleted = true; });
            
            final String targetAddress = barcodes.first.rawValue!;
            debugPrint('Target IP Found: $targetAddress');

            try {
              await platformEngine.invokeMethod('executeSendPipeline', {
                'address': targetAddress,
                'path': widget.folderToStream,
              });
            } catch (e) {
              debugPrint('Engine Execution Error: $e');
            }
            if (mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }
}

