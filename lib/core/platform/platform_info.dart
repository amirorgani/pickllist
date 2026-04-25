import 'package:flutter/foundation.dart';

/// Pure information about the runtime platform. Kept separate from
/// `dart:io` so that widgets can depend on this without pulling in IO.
class PlatformInfo {
  /// Creates platform metadata for routing and feature gates.
  const PlatformInfo({required this.targetPlatform, required this.isWeb});

  /// Creates platform metadata for the current Flutter runtime.
  factory PlatformInfo.current() =>
      PlatformInfo(targetPlatform: defaultTargetPlatform, isWeb: kIsWeb);

  /// Flutter target platform for this runtime.
  final TargetPlatform targetPlatform;

  /// Whether the app is running on the web platform.
  final bool isWeb;

  /// Whether this runtime is native Windows.
  bool get isWindows => !isWeb && targetPlatform == TargetPlatform.windows;

  /// Whether this runtime is native macOS.
  bool get isMacOS => !isWeb && targetPlatform == TargetPlatform.macOS;

  /// Whether this runtime is native Linux.
  bool get isLinux => !isWeb && targetPlatform == TargetPlatform.linux;

  /// Whether this runtime is a desktop target.
  bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Whether this runtime is native Android.
  bool get isAndroid => !isWeb && targetPlatform == TargetPlatform.android;

  /// Whether this runtime is native iOS.
  bool get isIOS => !isWeb && targetPlatform == TargetPlatform.iOS;

  /// Whether this runtime is a mobile target.
  bool get isMobile => isAndroid || isIOS;

  /// Manager-only features (Excel import, templates, history, user admin)
  /// are only exposed on Windows, per product spec.
  bool get managerFeaturesAvailable => isWindows;
}
