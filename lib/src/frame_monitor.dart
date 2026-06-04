import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'logger_utility.dart';

/// A high-performance, zero-dependency frame drop (jank) interception engine.
///
/// [JankScout] monitors the rendering pipeline of Flutter applications by listening
/// directly to the Dart VM's raw [FrameTiming] events. This class is designed as a
/// singleton and operates with production safety in mind: all timing hook logic and
/// active callbacks are wrapped within compile-time assertions. Consequently, in
/// `--release` builds, the entire interception pipeline is compiled out (tree-shaken),
/// leaving zero execution overhead and zero binary bloat.
class JankScout {
  // Private constructor to enforce the singleton pattern.
  JankScout._({required this.targetFps}) {
    _frameBudgetMs = 1000.0 / targetFps;
  }

  /// The active singleton instance, initialized only in debug mode.
  static JankScout? _instance;

  /// The target FPS (Frames Per Second) configured for the frame budget threshold.
  final double targetFps;

  /// The calculated frame budget ceiling in milliseconds.
  ///
  /// For instance:
  /// - 60 FPS target implies a frame budget of ~16.67ms.
  /// - 120 FPS target (high-refresh displays) implies a budget of ~8.33ms.
  late final double _frameBudgetMs;

  /// The current active route/screen name, updated via [JankScoutObserver].
  /// Time Complexity: O(1) read access during frame timing intercepts.
  static String _currentRoute = 'unknown_route';

  /// Internally updates the current route.
  /// Time Complexity: O(1).
  static void _setCurrentRoute(String? routeName) {
    _currentRoute = routeName ?? 'unknown_route';
  }

  /// Initializes the [JankScout] frame monitor singleton.
  ///
  /// [targetFps] specifies the base FPS of the target environment.
  /// Ensure that [WidgetsFlutterBinding.ensureInitialized] has been called
  /// prior to invoking this method.
  ///
  /// **Production Safety Guard:**
  /// The registration is wrapped inside a Dart compilation `assert` block.
  /// In release mode, assertions are not evaluated, meaning the singleton
  /// is never constructed, no engine hooks are registered, and no CPU cycles
  /// are spent.
  static void initialize({double targetFps = 60.0}) {
    assert(() {
      if (_instance == null) {
        _instance = JankScout._(targetFps: targetFps);
        _instance!._startMonitoring();
      }
      return true;
    }());
  }

  /// Registers the frame timings callback with the Flutter [SchedulerBinding].
  ///
  /// **Flutter Rendering Pipeline Lifecycle:**
  /// Flutter schedules and renders frames in a pipeline consisting of two main threads:
  /// 1. **UI Thread (Build Phase):** This thread runs your Dart code, executes layouts,
  ///    builds widgets, paints, and constructs a Layer tree. High build durations
  ///    indicate heavy operations in build methods, complex layouts, or costly computations.
  /// 2. **Raster Thread (Raster Phase):** This thread receives the Layer tree from the UI
  ///    thread and translates it into GPU commands (via Skia or Impeller), uploading textures
  ///    and talking directly to the GPU. High raster times indicate expensive raster actions like
  ///    excessive save layers, clipping, or complex vector graphics.
  ///
  /// The engine pipelines these phases, so UI thread work for Frame N and Raster thread work
  /// for Frame N-1 run concurrently. If *either* phase exceeds the frame budget, a frame drop
  /// (jank) occurs.
  void _startMonitoring() {
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  /// Processes raw [FrameTiming] events emitted by the Flutter Engine.
  ///
  /// Iterates through the list of recent frames. If a frame's total render span
  /// exceeds the calculated budget, it extracts performance metrics and delegates
  /// warning output to [LoggerUtility].
  ///
  /// Time Complexity: O(N) where N is the number of timings reported (typically 1 or a few).
  /// Space Complexity: O(1) auxiliary space.
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      // totalSpan includes vsync overhead, build, and raster times in microseconds.
      final double totalRenderMs = timing.totalSpan.inMicroseconds / 1000.0;

      if (totalRenderMs > _frameBudgetMs) {
        final double cpuBuildMs = timing.buildDuration.inMicroseconds / 1000.0;
        final double gpuRasterMs =
            timing.rasterDuration.inMicroseconds / 1000.0;

        // Hand off metrics to the logger.
        LoggerUtility.logJank(
          screenName: _currentRoute,
          totalRenderMs: totalRenderMs,
          cpuBuildMs: cpuBuildMs,
          gpuRasterMs: gpuRasterMs,
          frameBudgetMs: _frameBudgetMs,
        );
      }
    }
  }
}

/// A zero-dependency [NavigatorObserver] that tracks active screens.
///
/// Add this observer to your [MaterialApp.navigatorObservers] list. It intercepts
/// route transitions and notifies [JankScout] of the current active screen name.
///
/// **Production Safety Guard:**
/// All routing state propagation to the [JankScout] engine is wrapped in `assert` blocks,
/// ensuring zero tracking cost when compiling for production.
class JankScoutObserver extends NavigatorObserver {
  void _updateActiveRoute(Route<dynamic>? route) {
    assert(() {
      final String? name = route?.settings.name;
      JankScout._setCurrentRoute(name);
      return true;
    }());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateActiveRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateActiveRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateActiveRoute(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateActiveRoute(previousRoute);
  }
}
