import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UltraShareMaterialWrapper());
}

class UltraShareMaterialWrapper extends StatelessWidget {
  const UltraShareMaterialWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UltraShare',
      theme: ThemeData(useMaterialDesign3: true, colorSchemeSeed: Colors.deepPurple, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterialDesign3: true, colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const UltraShareDashboard(),
    );
  }
}

class UltraShareDashboard extends StatefulWidget {
  const UltraShareDashboard({super.key});
  @override
  State<UltraShareDashboard> createState() => _UltraShareDashboardState();
}

class _UltraShareDashboardState extends State<UltraShareDashboard> {
  bool _isEngineRunning = false;
  bool _isInitializing = false;
  String _localIPAddress = "Finding network connection...";
  Process? _backgroundEngineProcess;

  @override
  void initState() {
    super.initState();
    _fetchLocalNetworkIP();
  }

  Future<void> _fetchLocalNetworkIP() async {
    try {
      final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        setState(() { _localIPAddress = interfaces.first.addresses.first.address; });
      } else {
        setState(() { _localIPAddress = "127.0.0.1 (No Wi-Fi)"; });
      }
    } catch (e) {
      setState(() { _localIPAddress = "Error discovering network parameters"; });
    }
  }

  Future<void> toggleEngineState() async {
    if (_isEngineRunning) {
      _backgroundEngineProcess?.kill();
      setState(() { _isEngineRunning = false; });
      return;
    }
    setState(() { _isInitializing = true; });
    try {
      final byteData = await rootBundle.load('assets/bin/ultra_share');
      final binaryFile = File('${Directory.systemTemp.path}/ultra_share');
      await binaryFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes), flush: true);
      await Process.run('chmod', ['+x', binaryFile.path]);
      _backgroundEngineProcess = await Process.start(binaryFile.path, ['receive', '8080']);
      setState(() { _isEngineRunning = true; });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Engine Fault: $error')));
    } finally {
      setState(() { _isInitializing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('UltraShare Engine', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: colors.surfaceContainerHighest.withOpacity(0.4),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _isEngineRunning ? colors.primary : colors.errorContainer,
                      child: Icon(_isEngineRunning ? Icons.sensors_rounded : Icons.sensors_off_rounded, color: _isEngineRunning ? colors.onPrimary : colors.onErrorContainer),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEngineRunning ? 'RECEIVE SOCKET ACTIVE' : 'ENGINE DISARMED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isEngineRunning ? colors.primary : colors.error)),
                        Text(_isEngineRunning ? 'http://$_localIPAddress:8080' : 'Awaiting Initialization', style: const TextStyle(fontSize: 14)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _isInitializing ? null : toggleEngineState,
              icon: _isInitializing 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isEngineRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
              label: Text(_isInitializing ? 'Configuring Sockets...' : (_isEngineRunning ? 'Terminate Active Server' : 'Initialize Transport Sockets')),
              style: FilledButton.styleFrom(backgroundColor: _isEngineRunning ? colors.error : colors.primary),
            )
          ],
        ),
      ),
    );
  }
}
