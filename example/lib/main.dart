import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jank_scout/jank_scout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  JankScout.initialize(targetFps: 60.0);
  runApp(const JankScoutExampleApp());
}

class JankScoutExampleApp extends StatelessWidget {
  const JankScoutExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jank Scout Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardTheme: const CardThemeData(
          color: Color(0xFF161B22),
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF30363D), width: 1),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      navigatorObservers: [JankScoutObserver()],
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/details': (context) => const DetailsScreen(),
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  bool _isProcessing = false;
  String _performanceResult = 'Idle';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Blocks the UI thread synchronously for a specified duration.
  /// Demonstrates Event Loop Stall (Janky Execution).
  void _simulateJank(int milliseconds) {
    setState(() {
      _performanceResult = 'Running synchronous block... (UI Freezing)';
    });
    
    // Busy loop to block the main isolate
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < milliseconds) {
      // Synchronous block
    }

    setState(() {
      _performanceResult = 'Finished synchronous block (${milliseconds}ms).';
    });
  }

  /// Remediates jank by offloading the task using foundation's compute.
  Future<void> _remediateWithCompute(int milliseconds) async {
    setState(() {
      _isProcessing = true;
      _performanceResult = 'Running offloaded task via compute...';
    });

    // Run the computation on a background isolate spawned by Flutter/Dart
    final int loops = await compute(_heavyCpuTask, milliseconds);

    setState(() {
      _isProcessing = false;
      _performanceResult = 'Compute finished smoothly (Calculated $loops loops).';
    });
  }

  /// Remediates jank using pure manual concurrency: Isolate.spawn and Ports.
  Future<void> _remediateWithManualIsolate(int milliseconds) async {
    setState(() {
      _isProcessing = true;
      _performanceResult = 'Running manual Isolate.spawn...';
    });

    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _manualIsolateEntryPoint,
      _IsolateConfig(milliseconds, receivePort.sendPort),
    );

    // Await message back from the background isolate
    final int loops = await receivePort.first as int;

    // Clean up resources manually
    isolate.kill(priority: Isolate.beforeNextEvent);
    receivePort.close();

    setState(() {
      _isProcessing = false;
      _performanceResult = 'Manual Isolate finished (Calculated $loops loops).';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🕵️‍♂️ Jank Scout Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Thread Visualizer Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Visual Frame Indicator',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This ring rotates continuously. Stalling the event loop freezes the ring, while background isolates keep it spinning smoothly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2.0 * math.pi,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.transparent,
                                  width: 6,
                                ),
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFF58A6FF),
                                    Color(0xFFBC8CFF),
                                    Color(0xFFFF7B72),
                                    Color(0xFF3FB950),
                                    Color(0xFF58A6FF),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Telemetry Status: $_performanceResult',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF58A6FF)),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Jank Simulation Controls Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulate Performance Jank (UI Block)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD29922),
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isProcessing ? null : () => _simulateJank(80),
                        child: const Text('Trigger Severe Jank (80ms UI Block)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Remediation Controls Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remediated Concurrent execution',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Run the same 80ms CPU-heavy task off the main thread. The rotation spinner will continue smoothly without dropping frames.',
                        style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3FB950),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isProcessing ? null : () => _remediateWithCompute(80),
                        child: const Text('Run via compute() wrapper', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF58A6FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isProcessing ? null : () => _remediateWithManualIsolate(80),
                        child: const Text('Run via manual Isolate.spawn()', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Navigation Test Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Navigator Attribution Test',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF58A6FF)),
                          foregroundColor: const Color(0xFF58A6FF),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/details');
                        },
                        child: const Text('Push Details Screen', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  void _simulateJank(int milliseconds) {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < milliseconds) {
      // Synchronous block
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details Screen'),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.layers_outlined, size: 72, color: Color(0xFFBC8CFF)),
              const SizedBox(height: 16),
              const Text(
                'Route: /details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF85149),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _simulateJank(80),
                child: const Text('Trigger Jank here (80ms UI Block)'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Concurrency Helpers & Isolate Entrypoints
// (Must be top-level functions or static methods in Dart)
// =============================================================================

/// A CPU-bound task that runs loops for the specified duration.
int _heavyCpuTask(int milliseconds) {
  final stopwatch = Stopwatch()..start();
  int loops = 0;
  while (stopwatch.elapsedMilliseconds < milliseconds) {
    loops++;
  }
  return loops;
}

/// Helper class to pass multiple arguments to Isolate.spawn.
class _IsolateConfig {
  final int milliseconds;
  final SendPort sendPort;

  _IsolateConfig(this.milliseconds, this.sendPort);
}

/// Entrypoint for the manually spawned isolate.
void _manualIsolateEntryPoint(_IsolateConfig config) {
  final stopwatch = Stopwatch()..start();
  int loops = 0;
  while (stopwatch.elapsedMilliseconds < config.milliseconds) {
    loops++;
  }
  // Send the computed value back through the SendPort
  config.sendPort.send(loops);
}
