import 'package:flutter/material.dart';

import 'enums.dart';
import 'localization.dart';

/// Configuration for the Updater package.
///
/// Controls **when** and **how** update checks are performed,
/// what UI style is used, localization settings, and
/// platform-specific native update options.
///
/// All fields have sensible defaults and can be overridden
/// as needed:
///
/// ```dart
/// UpdateConfig(
///   checkInterval: Duration(days: 1),
///   snoozeDuration: Duration(hours: 6),
///   dialogStyle: UpgradeDialogStyle.material,
/// )
/// ```
class UpdateConfig {
  /// How often to check for updates (e.g., once a day).
  /// If null, checks every time init is called (unless snoozed).
  final Duration? checkInterval;

  /// How long to wait before showing the popup again after "Update Later" is clicked.
  /// Default: 1 day.
  final Duration snoozeDuration;

  // --- Display Options (V3) ---

  /// The visual style of the dialog.
  ///
  ///  - [UpgradeDialogStyle.material] — Material Design [AlertDialog].
  ///  - [UpgradeDialogStyle.cupertino] — iOS-style [CupertinoAlertDialog].
  ///  - [UpgradeDialogStyle.adaptive] — Automatically picks Material on
  ///    Android and Cupertino on iOS (default).
  final UpgradeDialogStyle dialogStyle;

  /// Whether to show the prompt text (e.g. "Would you like to update?").
  final bool showPrompt;

  /// Whether to show the Release Notes section.
  final bool showReleaseNotes;

  /// Whether to show the Ignore button.
  final bool showIgnore;

  /// Whether to show the Later button.
  final bool showLater;

  /// Whether the barrier is dismissible.
  final bool barrierDismissible;

  // --- Action Button Styles ---

  /// Custom [TextStyle] for the **"Update"** (primary) button.
  ///
  /// Applied to both Material `FilledButton` and Cupertino
  /// `CupertinoDialogAction` labels.
  /// If `null`, the platform default style is used.
  final TextStyle? updateButtonTextStyle;

  /// Custom [TextStyle] for the **"Later"** button.
  ///
  /// If `null`, the platform default style is used.
  final TextStyle? laterButtonTextStyle;

  /// Custom [TextStyle] for the **"Ignore"** button.
  ///
  /// If `null`, the platform default style is used.
  final TextStyle? ignoreButtonTextStyle;

  // --- Localization (V3) ---

  /// Localization messages.
  final UpdaterMessages? messages;

  /// Override language code.
  final String? languageCode;

  /// Override country code (unused for now, but kept for API match).
  final String? countryCode;

  // --- Native Android ---

  /// Whether to use Google Play's **Immediate** (blocking) In-App Update flow.
  ///
  /// When `true`, the system shows a full-screen update UI that blocks
  /// the user from using the app until the update is installed.
  /// Only takes effect on Android when an `AppUpdateInfo` is available.
  ///
  /// Mutually exclusive with [useAndroidNativeFlexibleUpdate].
  final bool useAndroidNativeImmediateUpdate;

  /// Whether to use Google Play's **Flexible** (background) In-App Update flow.
  ///
  /// When `true`, the update is downloaded in the background while the
  /// user continues using the app. A notification is shown when the
  /// download is complete.
  /// Only takes effect on Android when an `AppUpdateInfo` is available.
  ///
  /// Mutually exclusive with [useAndroidNativeImmediateUpdate].
  final bool useAndroidNativeFlexibleUpdate;

  // --- Debugging ---

  /// Forces the update dialog to appear regardless of version comparison.
  ///
  /// **Only works in `kDebugMode`** (ignored in release builds).
  /// Useful for testing the update UI on side-loaded or debug builds
  /// where the Play Store API returns "app not owned".
  final bool debugAlwaysShow;

  /// If `true`, the update dialog will only appear **once** per app
  /// session / lifecycle, regardless of other flags.
  ///
  /// Useful during development to avoid repeated dialogs on every
  /// hot-reload or resume.
  final bool debugDisplayOnce;

  /// Creates an [UpdateConfig] with the given options.
  ///
  /// All parameters are optional and have sensible defaults.
  const UpdateConfig({
    this.checkInterval,
    this.snoozeDuration = const Duration(days: 1),
    this.dialogStyle = UpgradeDialogStyle.adaptive,
    this.showPrompt = true,
    this.showReleaseNotes = true,
    this.showIgnore = true,
    this.showLater = true,
    this.barrierDismissible = false,
    this.updateButtonTextStyle,
    this.laterButtonTextStyle,
    this.ignoreButtonTextStyle,
    this.messages,
    this.languageCode,
    this.countryCode,
    this.useAndroidNativeImmediateUpdate = false,
    this.useAndroidNativeFlexibleUpdate = false,
    this.debugAlwaysShow = false,
    this.debugDisplayOnce = false,
    this.canPopScope,
    this.onPopInvoked,
  });

  /// Whether the dialog can be popped by the back button/System navigation.
  /// If null, it defaults to true for non-critical updates and false for critical updates.
  final bool? canPopScope;

  /// Callback when PopScope is invoked.
  final void Function(bool didPop)? onPopInvoked;
}
