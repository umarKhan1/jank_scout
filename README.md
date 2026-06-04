# jank_scout

[![Pub Version](https://img.shields.io/badge/pub-v0.0.1-blue.svg)](https://pub.dev/packages/jank_scout)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter SDK](https://img.shields.io/badge/flutter-v3.0.0+-blue.svg)](https://flutter.dev)

A highly performance-optimized, zero-dependency frame drop (jank) interception package for local Flutter development. 

`jank_scout` passively monitors the rendering pipeline of your application, detects frames that breach their target render budget, attributes them to the active navigator screen, and prints a detailed console breakdown—**without using intrusive UI overlays and without relying on heavy cloud-based APMs**.

---

## 🚀 Key Design Philosophies

1. **Zero UI Intrusion:** No floating widgets, charts, or graphs cluttering your app's interface. Performance metrics stay where they belong: in the development console.
2. **Manual Mastery (No CodeGen):** Written purely and explicitly in Dart. No fragile build runners, serialization libraries, or annotation processing required.
3. **Zero Third-Party Dependencies:** Relying exclusively on native APIs provided by the Flutter SDK. A completely clean and safe dependency tree.
4. **Production Asset Safety:** All registration hooks and active tracking calls are wrapped inside compile-time `assert` guards. When you compile a release build (`flutter build --release`), the entire package execution path is tree-shaken and **completely self-destructs**, leaving absolute zero runtime overhead or binary size impact.

---

## 📦 Installation

Add `jank_scout` to your project's `pubspec.yaml`:

```yaml
dependencies:
  jank_scout:
    path: # or version constraint if hosted on pub.dev
```

Then run `flutter pub get`.

---

## 🛠️ Quick Start

### 1. Initialize the Monitor

Call `JankScout.initialize()` in your application's `main()` entrypoint. 

> ⚠️ **Important:** Make sure to call `WidgetsFlutterBinding.ensureInitialized()` before initializing `JankScout`.

```dart
import 'package:flutter/material.dart';
import 'package:jank_scout/jank_scout.dart';

void main() {
  // 1. Ensure bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize JankScout with target device FPS
  // Supports high-refresh-rate displays (e.g. 120 FPS / 8.33ms budget)
  JankScout.initialize(targetFps: 60.0);

  runApp(const MyApp());
}
```

### 2. Configure Navigator Attribution

Add the `JankScoutObserver` to your root `MaterialApp`'s `navigatorObservers` array. This enables the engine to dynamically attribute frame drops to the active screen.

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jank Scout Demo',
      // Register the observer
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

## 📊 Terminal Output Showcase

When a frame drop occurs (e.g., rendering takes 28ms on a 60 FPS target where the budget is 16.67ms), `jank_scout` outputs a beautiful, colorized warning card to your terminal:

```text
┌─── [JANK SCOUT DETECTED FRAME DROP] ───────────────────────────
│ Screen: /details
│ Budget: 16.67 ms (Target FPS: 60)
│ Total: 28.42 ms (+11.75 ms / 170% of budget)
│ Timeline: [████████████████░░░░]
├─ Pipeline Breakdowns:
│   • UI Thread (CPU Build):   18.12 ms
│   • Raster Thread (GPU):    10.30 ms
└────────────────────────────────────────────────────────────────
```

---

## 🧠 Under the Hood: The Flutter Rendering Pipeline

To help you diagnose the root cause of jank, `jank_scout` breaks down the frame duration into the two critical phases of the Flutter rendering engine:

| Thread / Phase | Description | Common Bottlenecks |
| :--- | :--- | :--- |
| **UI Thread (CPU Build)** | Executes all Dart code, parses layouts, constructs widget trees, and produces layer trees. | • Complex layouts or deep widget trees.<br>• Performing heavy compute operations directly on the main isolate.<br>• Unoptimized state management triggering unnecessary subtree rebuilds. |
| **Raster Thread (GPU)** | Receives layer trees from the UI thread and translates them into GPU commands (using Skia or Impeller), uploading textures and rasterizing. | • Expensive operations like nested clipping, opacity overlays, or custom shaders.<br>• Large asset texture loading.<br>• High numbers of `saveLayer` calls. |

*Note: Since the UI thread and Raster thread run concurrently in a pipelined fashion (UI thread processes frame N while Raster thread renders frame N-1), a slow-down in either thread will trigger a frame drop.*

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
