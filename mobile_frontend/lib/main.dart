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
      theme: ThemeData(
        useMaterialDesign3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterialDesign3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
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
      final interfaces = await NetworkInterface.list(
        includeLoopback: false, 
        type: InternetAddressType.IPv4
      );
      
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        setState(() {
          _localIPAddress = interfaces.first.addresses.first.address;
        });
      } else {
        setState(() {
          _localIPAddress = "127.0.0.1 (No Wi-Fi Found)";
        });
      }
    } catch (e) {
      setState(() {
        _localIPAddress = "Error discovering network parameters";
      });
    }
  }

  Future<void> toggleEngineState() async {
    if (_isEngineRunning) {
      // Gracefully terminate the running process background task
      _backgroundEngineProcess?.kill();
      setState(() {
        _isEngineRunning = false;
      });
      return;
    }

    setState(() {
      _isInitializing = true;
    });

    try {
      // Extract the high-speed asset binary out onto mobile device application storage
      final byteData = await rootBundle.load('assets/bin/ultra_share');
      final internalDir = Directory.systemTemp.path;
      final binaryFile = File('$internalDir/ultra_share');
      
      await binaryFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );
      
      // Inject standard Linux execution safety bits
      await Process.run('chmod', ['+x', binaryFile.path]);
      
      // Fire up the streaming engine socket sub-process
      _backgroundEngineProcess = await Process.start(binaryFile.path, ['receive', '8080']);
      
      setState(() {
        _isEngineRunning = true;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Engine Initialization Fault: $error')),
      );
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _backgroundEngineProcess?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UltraShare Engine', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLocalNetworkIP,
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Network Parameter Dashboard Cards
              Card(
                elevation: 0,
                color: colors.surfaceContainerHighest.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _isEngineRunning ? colors.primary : colors.errorContainer,
                        radius: 24,
                        child: Icon(
                          _isEngineRunning ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                          color: _isEngineRunning ? colors.onPrimary : colors.onErrorContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEngineRunning ? 'RECEIVE SOCKET ACTIVE' : 'ENGINE DISARMED',
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                color: _isEngineRunning ? colors.primary : colors.error,
                                letterSpacing: 1.1
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEngineRunning ? 'http://$_localIPAddress:8080' : 'Awaiting Connection Initialization',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Section 2: Informational System Details Metrics
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Node IP Address', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(_localIPAddress, style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Target Core Gateway Port', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('8080', style: TextStyle(color: colors.secondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              
              // Section 3: Primary Control Engine Action Button
              _isInitializing
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : FilledButton.icon(
                      onPressed: toggleEngineState,
                      icon: Icon(_isEngineRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
                      label: Text(
                        _isEngineRunning ? 'Terminate Active Server' : 'Initialize Transport Sockets',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isEngineRunning ? colors.error : colors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

