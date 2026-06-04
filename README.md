# Jank Scout

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform Support](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20macos%20%7C%20web-blue.svg)](https://flutter.dev)
[![Flutter SDK](https://img.shields.io/badge/flutter-v3.0.0+-blue.svg)](https://flutter.dev)

Jank Scout is a lightweight, high-performance frame drop interception and telemetry package built for local Flutter development. It passively monitors rendering pipeline events, identifies frame timing drops that overrun the frame budget, and formats diagnostic telemetry reports into the developer console.

> [!NOTE]
> Unlike traditional APM packages or UI overlay extensions, Jank Scout is built to operate passively, cleanly, and safely.

---

## Technical Differences and Key Capabilities

* **Passive Terminal Telemetry:** There are no floating charts, graph windows, or overlay buttons blocking your touch boundaries or layout calculations. All diagnostics stream directly to the development console to keep your test environment clean.
* **Compile-Time Production Safety:**
  > [!IMPORTANT]
  > Every core monitoring route, callback hook, and telemetry string builder is wrapped inside strict compilation `assert` boundaries. When compiling release builds, the entire package implementation is completely tree-shaken by the compiler—leaving zero execution path overhead, zero background thread activity, and zero binary size bloat.
* **Zero Third-Party Dependencies:** Built completely using native Flutter SDK binding callbacks. It introduces no external dependencies to your project tree, preventing package-version conflicts and keeping your architecture clean.
* **Bottleneck Remediation Guidance:** Automatically divides latency reports into UI Thread (CPU Build) and Raster Thread (GPU) executions, providing dynamic structural diagnostic explanations to guide performance remediation.
* **Telemetry Cooldown and Noise Suppression:** Implements a `4ms` threshold buffer to ignore minor hardware jitter, paired with a `2.5-second` logging cooldown per route to completely eliminate terminal log flooding.

---

## Installation

Add `jank_scout` to the dependency list in your project's `pubspec.yaml` file:

```yaml
dependencies:
  jank_scout:
    path: /path/to/jank_scout
```

Then, fetch the package from your terminal:

```bash
flutter pub get
```

---

## Quick Start

### 1. Initialize the Telemetry Engine

Initialize the `JankScout` controller inside your application's `main()` entry function. 

> [!WARNING]
> Ensure that `WidgetsFlutterBinding.ensureInitialized()` has been executed prior to calling the initialization method.

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

Add `JankScoutObserver` to your `MaterialApp`'s `navigatorObservers` list to enable route-level telemetry mapping.

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
| TELEMETRY REPORT: 🚨 [PIPELINE CRITICAL INTERRUPT]
+----------------------------------------------------------------------+
| Target Route: /details
| Budget: 16.67 ms (Target FPS: 60)
| Frame Render Time: 76.50 ms (Overrun: 358.9%, +59.83 ms)
| Thread Breakdowns:
|   - UI Thread (CPU Build):  68.20 ms
|   - Raster Thread (GPU):   8.30 ms
+----------------------------------------------------------------------+
| Bottleneck Analysis:
| ❌ BOTTLENECK: UI Thread (CPU Boundary). Diagnostic: Excessive execution cycle detected on the Dart isolate runtime loop. Remediate by auditing synchronous serialization, unoptimized layout passes, or high-frequency state emissions violating state boundary conditions.
+----------------------------------------------------------------------+
```

---

## Architectural Breakdown

Jank Scout separates performance bottlenecks into the two primary execution domains of the Flutter rendering pipeline:

| Pipeline Thread | Description | Common Bottlenecks |
| :--- | :--- | :--- |
| **UI Thread (CPU Build)** | Executes all Dart application code, handles layout calculations, reconstructs widget trees, and produces layer trees. | • Heavy operations in build methods<br>• Synchronous JSON parsing on the main isolate<br>• Unoptimized state changes triggering deep subtree rebuilds |
| **Raster Thread (GPU)** | Receives the Layer tree from the UI thread, translates it into GPU instructions (via Skia or Impeller), and rasterizes it. | • Complex shape clipping<br>• Excessive `saveLayer` compositions<br>• Loading unoptimized high-resolution image assets |

---

## License

This project is licensed under the MIT License. See the [LICENSE](file:///Users/muhammadomar/Documents/projects/jank_scout/LICENSE) file for details.
