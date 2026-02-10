import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../updater.dart';
import 'update_controller.dart';

/// The core update-checking engine.
///
/// Orchestrates the complete update lifecycle:
///
/// 1. **Frequency check** — skips if checked too recently
///    (controlled by [UpdateConfig.checkInterval]).
/// 2. **Fetch** — retrieves [UpdateInfo] from the configured
///    [UpdateSource].
/// 3. **Version comparison** — determines whether an update
///    is available (or forced via [UpdateConfig.debugAlwaysShow]).
/// 4. **Snooze check** — skips if the user recently tapped
///    "Later" (controlled by [UpdateConfig.snoozeDuration]).
/// 5. **Presentation** — shows a dialog using the platform
///    native flow, a custom [builder], or the built-in
///    Material / Cupertino dialog.
///
/// You usually don't need to use this class directly — prefer
/// [Updater.init] or [UpdaterListener] instead.
class UpdateManager {
  /// SharedPreferences key for the last time the user tapped "Later".
  static const String kLastDismissedKey = 'updater_last_dismissed';

  /// SharedPreferences key for the last time an update check was performed.
  static const String kLastCheckedKey = 'updater_last_checked';

  /// The data source used to fetch remote version information.
  final UpdateSource source;

  /// Configuration that controls check intervals, UI style,
  /// localization, and more.
  final UpdateConfig config;

  /// Called when the update dialog is presented to the user.
  final VoidCallback? onUpdateShown;

  /// Called when the user dismisses or taps "Later" on the dialog.
  final VoidCallback? onUpdateIgnored;

  /// Called when the user taps "Update" and is redirected to the store.
  final VoidCallback? onUpdateAccepted;

  /// Called when an error occurs during the update check.
  ///
  /// Receives the error message as a [String].
  final Function(String error)? onError;

  /// Guards against showing multiple dialogs simultaneously.
  bool _isShowing = false;

  /// Creates an [UpdateManager].
  ///
  /// - [source] — where to fetch update info from.
  /// - [config] — how the check and dialog should behave.
  /// - [onUpdateShown] — fires when the dialog is shown.
  /// - [onUpdateIgnored] — fires when the user taps "Later".
  /// - [onUpdateAccepted] — fires when the user taps "Update".
  /// - [onError] — fires on any error during the check.
  UpdateManager({
    required this.source,
    required this.config,
    this.onUpdateShown,
    this.onUpdateIgnored,
    this.onUpdateAccepted,
    this.onError,
  });

  /// Performs the update check and optionally shows a dialog.
  ///
  /// **Parameters:**
  ///
  /// - [context] — A mounted [BuildContext] used to display the dialog.
  ///
  /// - [force] — If `true`, ignores [UpdateConfig.checkInterval]
  ///   and snooze state, forcing a fresh check.
  ///
  /// - [builder] — An optional builder that **replaces the entire
  ///   default dialog** with a custom widget. Receives:
  ///   - `context` — The dialog's [BuildContext].
  ///   - `info` — The [UpdateInfo] with version & release notes.
  ///   - `update` — Callback to trigger the store redirect.
  ///   - `later` — Callback to snooze the update.
  ///
  /// - [dialogActionsBuilder] — An optional builder that **replaces
  ///   only the action buttons** of the default dialog.
  ///   Receives the same parameters as [builder].
  Future<void> check(
    BuildContext context, {
    bool force = false,
    UpdateDialogBuilder? builder,
    UpdateActionsBuilder? dialogActionsBuilder,
  }) async {
    try {
      // 1. Check Frequency (Skip if too soon and not forced)
      // Debug Always Show overrides this check.
      if (!force && config.checkInterval != null && !config.debugAlwaysShow) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheckedStr = prefs.getString(kLastCheckedKey);
        if (lastCheckedStr != null) {
          final lastChecked = DateTime.tryParse(lastCheckedStr);
          if (lastChecked != null) {
            if (DateTime.now().difference(lastChecked) <
                config.checkInterval!) {
              return; // Skip check
            }
          }
        }
      }

      // 2. Fetch
      UpdateInfo? info;
      try {
        info = await source.fetchUpdateInfo();
      } catch (e) {
        if (!config.debugAlwaysShow) {}
      }

      if (info == null) {
        return; // No info and not (debug + failed)
      }

      // Save check time
      if (config.checkInterval != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          kLastCheckedKey,
          DateTime.now().toIso8601String(),
        );
      }

      // 3. Debug Force vs Logic
      bool shouldShow = info.isUpdateAvailable;

      // Feature: debugAlwaysShow only works in Debug Mode
      if (config.debugAlwaysShow && kDebugMode) {
        shouldShow = true;
      }

      if (!shouldShow) return;

      // 4. Snooze Check
      if (!config.debugAlwaysShow && !info.isCritical) {
        final prefs = await SharedPreferences.getInstance();
        final lastDismissedStr = prefs.getString(kLastDismissedKey);
        if (lastDismissedStr != null) {
          final lastDismissed = DateTime.tryParse(lastDismissedStr);
          if (lastDismissed != null) {
            if (DateTime.now().difference(lastDismissed) <
                config.snoozeDuration) {
              return; // Snoozed
            }
          }
        }
      }

      // 5. Present
      if (context.mounted) {
        _presentUpdate(context, info, builder, dialogActionsBuilder);
      }
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  Future<void> _presentUpdate(
    BuildContext context,
    UpdateInfo info,
    UpdateDialogBuilder? builder,
    UpdateActionsBuilder? dialogActionsBuilder,
  ) async {
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

    // Custom UI
    onUpdateShown?.call();

    Future<void> onUpdate() async {
      await UpdateController(
        config: config,
        onError: onError,
      ).performUpdate(info, onUpdateAccepted: onUpdateAccepted);
    }

    Future<void> onLater() async {
      onUpdateIgnored?.call();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        kLastDismissedKey,
        DateTime.now().toIso8601String(),
      );
      if (context.mounted) Navigator.of(context).pop();
    }

    if (!context.mounted) return;

    if (_isShowing) return;
    _isShowing = true;

    final canPop = config.canPopScope ?? !info.isCritical;

    if (builder != null) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible:
              !info.isCritical &&
              (config.barrierDismissible || config.showLater),
          builder: (ctx) => PopScope(
            canPop: canPop,
            onPopInvokedWithResult: (didPop, result) =>
                config.onPopInvoked?.call(didPop),
            child: Material(
              type: MaterialType.transparency,
              child: builder(ctx, info, onUpdate, onLater),
            ),
          ),
        ).then((_) => _isShowing = false);
      } else {
        _isShowing = false;
      }
    } else {
      if (!context.mounted) {
        _isShowing = false;
        return;
      }

      await _showDefaultDialog(
        context,
        info,
        onUpdate,
        onLater,
        canPop: canPop,
      );
      _isShowing = false;
    }
  }

  Future<void> _showDefaultDialog(
    BuildContext context,
    UpdateInfo info,
    VoidCallback onUpdate,
    VoidCallback onLater, {
    required bool canPop,
  }) async {
    final style = config.dialogStyle.resolved;
    final messages =
        config.messages ?? UpdaterMessages(languageCode: config.languageCode);
    final title = Text(messages.message(UpdaterMessage.title));

    final appName = (await PackageInfo.fromPlatform()).appName;
    final bodyText = messages
        .message(UpdaterMessage.body)
        .replaceAll('{{appName}}', appName)
        .replaceAll(
          '{{currentInstalledVersion}}',
          info.currentVersion.toString(),
        )
        .replaceAll('{{latestVersion}}', info.latestVersion.toString());

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bodyText),
        if (config.showPrompt) ...[
          const SizedBox(height: 8),
          Text(messages.message(UpdaterMessage.prompt)),
        ],
        if (config.showReleaseNotes &&
            info.releaseNotes != null &&
            info.releaseNotes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            messages.message(UpdaterMessage.releaseNotes),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(info.releaseNotes!, style: const TextStyle(fontSize: 13)),
        ],
      ],
    );

    final actions = <Widget>[
      if (config.showIgnore)
        if (style == UpgradeDialogStyle.cupertino)
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              messages.message(UpdaterMessage.buttonTitleIgnore),
              style: config.ignoreButtonTextStyle,
            ),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              messages.message(UpdaterMessage.buttonTitleIgnore).toUpperCase(),
              style: config.ignoreButtonTextStyle,
            ),
          ),

      if (!info.isCritical && config.showLater)
        if (style == UpgradeDialogStyle.cupertino)
          CupertinoDialogAction(
            onPressed: onLater,
            child: Text(
              messages.message(UpdaterMessage.buttonTitleLater),
              style: config.laterButtonTextStyle,
            ),
          )
        else
          TextButton(
            onPressed: onLater,
            child: Text(
              messages.message(UpdaterMessage.buttonTitleLater).toUpperCase(),
              style: config.laterButtonTextStyle,
            ),
          ),

      if (style == UpgradeDialogStyle.cupertino)
        CupertinoDialogAction(
          onPressed: onUpdate,
          isDefaultAction: true,
          child: Text(
            messages.message(UpdaterMessage.buttonTitleUpdate),
            style: config.updateButtonTextStyle,
          ),
        )
      else
        FilledButton(
          onPressed: onUpdate,
          child: Text(
            messages.message(UpdaterMessage.buttonTitleUpdate).toUpperCase(),
            style: config.updateButtonTextStyle,
          ),
        ),
    ];

    if (style == UpgradeDialogStyle.cupertino) {
      await showCupertinoDialog(
        context: context,
        barrierDismissible: !info.isCritical && config.barrierDismissible,
        builder: (ctx) => PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, result) =>
              config.onPopInvoked?.call(didPop),
          child: CupertinoAlertDialog(
            title: title,
            content: content,
            actions: actions,
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        barrierDismissible: !info.isCritical && config.barrierDismissible,
        builder: (ctx) => PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, result) =>
              config.onPopInvoked?.call(didPop),
          child: AlertDialog(
            title: title,
            content: SingleChildScrollView(child: content),
            actions: actions,
          ),
        ),
      );
    }
  }
}
