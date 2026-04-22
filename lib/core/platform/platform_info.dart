import 'package:flutter/foundation.dart';

/// Pure information about the runtime platform. Kept separate from
/// `dart:io` so that widgets can depend on this without pulling in IO.
class PlatformInfo {
  const PlatformInfo({required this.targetPlatform, required this.isWeb});

  final TargetPlatform targetPlatform;
  final bool isWeb;

  bool get isWindows => !isWeb && targetPlatform == TargetPlatform.windows;
  bool get isMacOS => !isWeb && targetPlatform == TargetPlatform.macOS;
  bool get isLinux => !isWeb && targetPlatform == TargetPlatform.linux;
  bool get isDesktop => isWindows || isMacOS || isLinux;
  bool get isAndroid => !isWeb && targetPlatform == TargetPlatform.android;
  bool get isIOS => !isWeb && targetPlatform == TargetPlatform.iOS;
  bool get isMobile => isAndroid || isIOS;

  /// Manager-only features (Excel import, templates, history, user admin)
  /// are only exposed on Windows, per product spec.
  bool get managerFeaturesAvailable => isWindows;

  static PlatformInfo current() =>
      PlatformInfo(targetPlatform: defaultTargetPlatform, isWeb: kIsWeb);
}
