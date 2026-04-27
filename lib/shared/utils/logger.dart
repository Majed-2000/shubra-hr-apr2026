import 'package:flutter/foundation.dart';

/// Debug-only log. Compiled out of release builds.
///
/// Use instead of `print` so production binaries stay quiet and never leak
/// data to system logs.
void logD(Object? message) {
  if (kDebugMode) {
    debugPrint(message?.toString());
  }
}
