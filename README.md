# Jank Scout

Jank Scout is a lightweight, high-performance frame drop interception and telemetry package built for local Flutter development. It passively monitors rendering pipeline events, identifies frame timing drops that overrun the frame budget, and formats diagnostic telemetry reports into the developer console.

Unlike traditional APM packages or UI overlay extensions, Jank Scout is built to operate passively, cleanly, and safely.

---

## Technical Differences and Key Capabilities

1. Passive Terminal Telemetry: There are no floating charts, graph windows, or overlay buttons blocking your touch boundaries or layout calculations. All diagnostics stream to the development console.
2. Compile-Time Production Safety: Every core monitoring route, callback hook, and telemetry string builder is wrapped inside compilation assert boundaries. When compiling release builds, the entire package implementation is tree-shaken by the compiler, leaving zero execution path overhead, zero background thread activity, and zero binary size bloat.
3. Zero Third-Party Dependencies: Built completely using native Flutter SDK binding callbacks. It introduces no external dependencies to your project tree, preventing package-version conflicts.
4. Bottleneck Remediation Guidance: Automatically divides latency reports into UI Thread (CPU Build) and Raster Thread (GPU) executions, providing dynamic structural diagnostic explanations to guide performance remediation.
5. Telemetry Cooldown and Noise Suppression: Implements a 4ms threshold buffer to ignore minor hardware jitter, paired with a 2.5-second logging cooldown per route to eliminate terminal log flooding.

---

## Installation

Add jank_scout to the dependency list in your project pubspec.yaml file:

```yaml
dependencies:
  jank_scout:
    path: /path/to/jank_scout
```

Then run the package installation command:

```bash
flutter pub get
```

---

## Quick Start

### 1. Initialize the Telemetry Engine

Initialize the JankScout controller inside your application main entry function. Ensure that WidgetsFlutterBinding.ensureInitialized has been executed beforehand.

```dart
import 'package:flutter/material.dart';
import 'package:jank_scout/jank_scout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize JankScout targeting the device refresh rate (e.g., 60 FPS)
  JankScout.initialize(targetFps: 60.0);

  runApp(const MyApp());
}
```

### 2. Configure Navigator Attribution

Add JankScoutObserver to your MaterialApp navigatorObservers list to enable route-level telemetry mapping.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Performance Testing App',
      navigatorObservers: [JankScoutObserver()],
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/details': (context) => const DetailsScreen(),
      },
    );
  }
}
```

---

## Telemetry Report Format

When a frame overrun is captured, a structured ASCII telemetry card is printed to the console:

```text
+----------------------------------------------------------------------+
| TELEMETRY REPORT: [PIPELINE CRITICAL INTERRUPT]
+----------------------------------------------------------------------+
| Target Route: /details
| Budget: 16.67 ms (Target FPS: 60)
| Frame Render Time: 76.50 ms (Overrun: 358.9%, +59.83 ms)
| Thread Breakdowns:
|   - UI Thread (CPU Build):  68.20 ms
|   - Raster Thread (GPU):   8.30 ms
+----------------------------------------------------------------------+
| Bottleneck Analysis:
| BOTTLENECK: UI Thread (CPU Boundary). Diagnostic: Excessive execution cycle detected on the Dart isolate runtime loop. Remediate by auditing synchronous serialization, unoptimized layout passes, or high-frequency state emissions violating state boundary conditions.
+----------------------------------------------------------------------+
```

---

## Architectural Breakdown

Jank Scout separates bottlenecks into two primary threads:

| Pipeline Thread | Description | Common Bottlenecks |
| :--- | :--- | :--- |
| UI Thread (CPU Build) | Executes Dart code, widget tree reconstructions, layout measurements, and painting layers. | Excessive operations in build methods, synchronous JSON parsing, or heavy business logic blocking the isolate event loop. |
| Raster Thread (GPU) | Converts paint layers into GPU instructions (via Skia or Impeller) and draws them. | Complex clips, nested saveLayers, texture caching issues, or rendering massive image assets. |

---

## License

MIT License. See LICENSE file for details.
