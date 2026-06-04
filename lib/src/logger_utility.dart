import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A performance-optimized telemetry logger for development-time frame analysis.
///
/// [LoggerUtility] manages jank telemetry logging using native [developer.log]
/// and [debugPrint] channels, structured as a clean ASCII report.
///
/// **Production Safety Guard:**
/// All formatting, logic checks, and console logging are wrapped in standard Dart
/// `assert` blocks. When compiled in release mode, the methods are completely tree-shaken,
/// adding zero runtime or binary overhead.
class LoggerUtility {
  // Private constructor to prevent instantiation.
  LoggerUtility._();

  /// Map tracking the timestamp of the last logged telemetry report per active route.
  /// Used to implement a 2.5-second logging cooldown per screen name.
  static final Map<String, DateTime> _lastLogTimes = {};

  /// Formats and logs a frame drop telemetry report to the development console.
  ///
  /// **Features:**
  /// 1. **Overhead Threshold Buffer:** Ignore micro-drops (total render time <= budget + 4ms)
  ///    to prevent console spam from minor system jitter.
  /// 2. **Cooldown Filter:** If a telemetry report was printed less than 2.5 seconds ago
  ///    for the exact same active route, discard the duplicate log.
  /// 3. **Classification Labels:** Automatically classifies reports as `⚠️ [PERFORMANCE DEGRADATION]`
  ///    or `🚨 [PIPELINE CRITICAL INTERRUPT]` depending on budget overrun severity.
  /// 4. **Root-Cause Analysis Engine:** Assesses CPU vs. GPU bottlenecks and writes detailed
  ///    remediation steps.
  /// 5. **Minimalist Plain-Text Matrix:** Structured ASCII box formatting with zero ANSI code bleeding.
  static void logJank({
    required String screenName,
    required double totalRenderMs,
    required double cpuBuildMs,
    required double gpuRasterMs,
    required double frameBudgetMs,
  }) {
    assert(() {
      // 1. Overhead Threshold Buffer
      if (totalRenderMs <= frameBudgetMs + 4.0) {
        return true;
      }

      // 2. Cooldown Filter (2.5 seconds per active route)
      final now = DateTime.now();
      final lastLog = _lastLogTimes[screenName];
      if (lastLog != null && now.difference(lastLog).inMilliseconds < 2500) {
        return true;
      }
      _lastLogTimes[screenName] = now;

      // 3. Classification Labels & Calculations
      final double excessMs = totalRenderMs - frameBudgetMs;
      final double overrunPct = (excessMs / frameBudgetMs) * 100.0;
      
      final String classification = overrunPct <= 50.0
          ? '⚠️ [PERFORMANCE DEGRADATION]'
          : '🚨 [PIPELINE CRITICAL INTERRUPT]';

      // 4. Root-Cause Analysis Engine
      String bottleneckAdvice;
      if (cpuBuildMs > gpuRasterMs) {
        bottleneckAdvice = '❌ BOTTLENECK: UI Thread (CPU Boundary). Diagnostic: Excessive execution cycle detected on the Dart isolate runtime loop. Remediate by auditing synchronous serialization, unoptimized layout passes, or high-frequency state emissions violating state boundary conditions.';
      } else {
        bottleneckAdvice = '❌ BOTTLENECK: Raster Thread (GPU Boundary). Diagnostic: Layer tree rendering budget exceeded. Remediate by auditing expensive composition passes, unindexed clipping boundaries, or raw texture memory allocations.';
      }

      // 5. Minimalist Plain-Text Matrix Formatting
      final buffer = StringBuffer()
        ..writeln('+----------------------------------------------------------------------+')
        ..writeln('| TELEMETRY REPORT: $classification')
        ..writeln('+----------------------------------------------------------------------+')
        ..writeln('| Target Route: $screenName')
        ..writeln('| Budget: ${frameBudgetMs.toStringAsFixed(2)} ms (Target FPS: ${(1000.0 / frameBudgetMs).toStringAsFixed(0)})')
        ..writeln('| Frame Render Time: ${totalRenderMs.toStringAsFixed(2)} ms (Overrun: ${overrunPct.toStringAsFixed(1)}%, +${excessMs.toStringAsFixed(2)} ms)')
        ..writeln('| Thread Breakdowns:')
        ..writeln('|   - UI Thread (CPU Build):  ${cpuBuildMs.toStringAsFixed(2)} ms')
        ..writeln('|   - Raster Thread (GPU):   ${gpuRasterMs.toStringAsFixed(2)} ms')
        ..writeln('+----------------------------------------------------------------------+')
        ..writeln('| Bottleneck Analysis:')
        ..writeln('| $bottleneckAdvice')
        ..writeln('+----------------------------------------------------------------------+');

      final String logMsg = buffer.toString();
      developer.log(logMsg, name: 'jank_scout');
      debugPrint(logMsg);

      return true;
    }());
  }
}
