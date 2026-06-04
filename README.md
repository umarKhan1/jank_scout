# Jank Scout

[![Flutter compatibility](https://img.shields.io/badge/flutter-v3.0.0+-blue?style=flat)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20macos%20%7C%20web-blue?style=flat)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat)](https://opensource.org/licenses/MIT)
[![Dependencies](https://img.shields.io/badge/dependencies-zero-success?style=flat)](https://github.com/umarKhan1/jank_scout)

Jank Scout is a lightweight, high-performance frame drop interception and telemetry package built for local Flutter development. It passively monitors rendering pipeline events, identifies frame timing drops that overrun the frame budget, and formats diagnostic telemetry reports into the developer console.

> [!NOTE]
> Unlike traditional APM packages or UI overlay extensions, Jank Scout is built to operate passively, cleanly, and safely.

---

## Why Jank Scout? (The Problem It Solves)

Modern Flutter performance profiling typically forces developers to choose between two sub-optimal approaches:

* **VS. Flutter DevTools:** While powerful, DevTools requires manual setup, launching separate browser tabs, keeping web sockets connected, and explicitly recording performance sessions. It is an active debugging utility rather than a passive, continuous checker. Jank Scout requires **zero browser tabs** and monitors your app passively, sending automated telemetry straight to your terminal as you develop.
* **VS. Production APMs (e.g., Sentry, Firebase Performance):** Heavy production performance monitoring frameworks are designed for live user monitoring. They add runtime overhead, make blocking network requests, introduce heavy dependency trees, and increase your final app size. Jank Scout is a local-only tool that uses native framework callbacks, has **zero package dependencies**, and **completely self-destructs (100% tree-shaken out)** during release compilation, leaving absolutely zero runtime or binary bloat.

---

## Technical Differences and Key Capabilities

* **Passive Terminal Telemetry:** There are no floating charts, graph windows, or overlay widgets blocking your touch boundaries or layout calculations. All diagnostics stream directly to the development console to keep your test environment clean.
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
  jank_scout: ^0.0.1
```

Or install it directly from your terminal:

```bash
flutter pub add jank_scout
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

## Contributing

Contributions are welcome! If you encounter any bugs, have feature requests, or want to improve the codebase:

1. **Reporting Bugs:** Please open an issue on the GitHub repository detailing the problem, your Flutter environment, and steps to reproduce.
2. **Submitting Pull Requests:** Fork the repository, create a descriptive branch, implement your changes (ensuring `flutter analyze` passes with zero issues), and open a pull request.
3. **Local Testing:** Use the included `example/` project to verify modifications and test performance timings under both synchronous blocks and isolate concurrency.

---

## Maintainer

Jank Scout is created and maintained by **Muhammad Omar**. 

* **LinkedIn:** [linkedin.com/in/muhammad-omar-0335](https://www.linkedin.com/in/muhammad-omar-0335/)
* **Website:** [momarkhan.com](http://momarkhan.com)

---

## License

This project is licensed under the MIT License. See the [LICENSE](file:///Users/muhammadomar/Documents/projects/jank_scout/LICENSE) file for details.
