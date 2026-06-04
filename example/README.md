# Jank Scout Example

This sub-project demonstrates a complete integration of the jank_scout frame drop monitor inside a standard Flutter application. It showcases performance telemetry, event loop starvation, and the remediation of jank using Dart background isolates.

---

## What This Example Demonstrates

1. Automatic Setup: Demonstrates how to initialize JankScout at startup and register JankScoutObserver in MaterialApp to track active screen paths.
2. Event Loop Starvation: Provides a button that runs a synchronous busy-loop directly on Flutter's main UI Thread. This freezes the continuous spinner animation on screen and triggers a severe performance interrupt warning in the console.
3. Concurrency Remediation: Implements two ways to offload the same CPU-intensive computation off the main thread:
   - Using the compute() utility wrapper.
   - Spawining a background thread manually using Isolate.spawn, ReceivePort, and SendPort.
   Running either concurrent task keeps the visual spinner running smoothly at 60 FPS without printing frame-drop warnings.

---

## How to Run the Example App

Ensure you have a device or simulator connected by running:

```bash
flutter devices
```

Then, run the application from this directory:

```bash
flutter run
```

Or target a specific platform like macOS desktop directly:

```bash
flutter run -d macos
```

---

## Testing Scenarios

1. Cold Start Jank: Look at the console logs immediately after app startup. You will see initial reports of frame drops indicating Raster thread overhead as the engine initializes layout caches and shaders.
2. Trigger UI Thread Block: Tap the "Trigger Severe Jank (80ms UI Block)" button. The visual circle will pause, and the terminal will output a TELEMETRY REPORT highlighting a UI Thread CPU bottleneck.
3. Run Concurrently: Tap "Run via compute() wrapper" or "Run via manual Isolate.spawn()". The task will complete successfully, the visual circle will spin without stuttering, and no frame warnings will print, confirming the jank has been resolved.
4. Push Details Screen: Push the secondary details screen and trigger jank there to verify that the active screen name changes to /details in the telemetry.
