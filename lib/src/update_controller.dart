import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'update_config.dart';

/// Handles the **actual update action** once the user decides to update.
///
/// Depending on the platform and [UpdateConfig], this either:
///
/// * Triggers the **Android In-App Update** native flow (immediate
///   or flexible), or
/// * Launches the **store URL** (Play Store `market://` intent on
///   Android, App Store URL on iOS) via `url_launcher`.
///
/// This is an internal helper — you typically don't need to use
/// it directly. It is called by [UpdateManager] and [UpgradeCard].
class UpdateController {
  /// The configuration that determines which native update
  /// strategy to use (immediate, flexible, or URL launch).
  final UpdateConfig config;

  /// Called when the update action fails.
  ///
  /// Receives the error message as a [String].
  final Function(String error)? onError;

  /// Creates an [UpdateController].
  ///
  /// - [config] — **(required)** The update configuration.
  /// - [onError] — optional error callback.
  UpdateController({required this.config, this.onError});

  /// Executes the update action for the given [info].
  ///
  /// **Parameters:**
  ///
  /// - [info] — The [UpdateInfo] describing the available update.
  ///   Used to determine the platform data and fallback URL.
  ///
  /// - [onUpdateAccepted] — Optional callback fired after the user
  ///   is successfully redirected to the update.
  ///
  /// **Behaviour:**
  ///
  /// 1. If on Android with a native `AppUpdateInfo`:
  ///    - Uses [InAppUpdate.performImmediateUpdate] if
  ///      [UpdateConfig.useAndroidNativeImmediateUpdate] is `true`.
  ///    - Uses [InAppUpdate.startFlexibleUpdate] if
  ///      [UpdateConfig.useAndroidNativeFlexibleUpdate] is `true`.
  /// 2. Otherwise, launches the store URL via `url_launcher`.
  Future<void> performUpdate(
    UpdateInfo info, {
    VoidCallback? onUpdateAccepted,
  }) async {
    // Android Native Flow
    if (Platform.isAndroid && info.platformData is AppUpdateInfo) {
      if (config.useAndroidNativeImmediateUpdate) {
        try {
          await InAppUpdate.performImmediateUpdate();
          onUpdateAccepted?.call();
          return;
        } catch (e) {
          onError?.call("Native Immediate Update failed: $e");
        }
      } else if (config.useAndroidNativeFlexibleUpdate) {
        try {
          await InAppUpdate.startFlexibleUpdate();
          InAppUpdate.completeFlexibleUpdate().then((_) {
            onUpdateAccepted?.call();
          });
          return;
        } catch (e) {
          onError?.call("Native Flexible Update failed: $e");
        }
      }
    }

    // Default Flow (URL Launch)
    onUpdateAccepted?.call();
    if (Platform.isAndroid) {
      String packageName = '';
      try {
        final pkg = await PackageInfo.fromPlatform();
        packageName = pkg.packageName;
      } catch (_) {}

      final url = Uri.parse("market://details?id=$packageName");
      if (packageName.isNotEmpty && await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (info.updateUrl != null) launchUrl(Uri.parse(info.updateUrl!));
      }
    } else {
      if (info.updateUrl != null) {
        launchUrl(
          Uri.parse(info.updateUrl!),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }
}
