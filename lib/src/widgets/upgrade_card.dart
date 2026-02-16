import 'package:flutter/cupertino.dart'; // Add cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add shared_preferences

import '../update_controller.dart';
import '../../app_updater_flutter.dart';

/// A builder that **replaces the entire [UpgradeCard] content**
/// with a custom widget.
///
/// Parameters:
/// - `context` — The current [BuildContext].
/// - `info` — The [UpdateInfo] containing current/latest versions
///   and release notes.
/// - `onUpdate` — Callback to trigger the store redirect. Call
///   this when the user taps your "Update" button.
/// - `onLater` — Callback to snooze the card. Records the
///   dismiss time and hides the card.
typedef UpgradeCardBuilder =
    Widget Function(
      BuildContext context,
      UpdateInfo info,
      VoidCallback onUpdate,
      VoidCallback onLater,
    );

/// A builder that **replaces only the action buttons** of the
/// default [UpgradeCard].
///
/// Must return a `List<Widget>` of action buttons. Receives the
/// same parameters as [UpgradeCardBuilder]:
/// - `context` — The current [BuildContext].
/// - `info` — The [UpdateInfo] with version & release notes.
/// - `onUpdate` — Callback to trigger the store redirect.
/// - `onLater` — Callback to snooze and hide the card.
typedef UpgradeCardActionsBuilder =
    List<Widget> Function(
      BuildContext context,
      UpdateInfo info,
      VoidCallback onUpdate,
      VoidCallback onLater,
    );

/// A self-contained card widget that displays an update prompt
/// **inline** (e.g., on a Settings page), as opposed to a dialog.
///
/// It replicates the same update-checking logic as [UpdateManager]:
/// frequency checks, snooze handling, debug overrides, and version
/// comparison — but renders the result as a [Card] instead of a
/// modal dialog.
///
/// The card is **invisible** (`SizedBox.shrink`) when no update is
/// available or when the snooze period has not elapsed.
///
/// Example:
/// ```dart
/// UpgradeCard(
///   config: UpdateConfig(snoozeDuration: Duration(minutes: 5)),
///   source: StoreUpdateSource(),
/// )
/// ```
class UpgradeCard extends StatefulWidget {
  /// Configuration for the update check.
  ///
  /// Controls check intervals, snooze duration, dialog style,
  /// localization, and debug flags.
  /// See [UpdateConfig] for all available options.
  final UpdateConfig config;

  /// The data source to fetch update information from.
  ///
  /// Defaults to [StoreUpdateSource] (Play Store / App Store).
  /// Use [JsonUpdateSource] for a custom endpoint.
  final UpdateSource source;

  /// Outer margin for the [Card] widget.
  ///
  /// Defaults to `EdgeInsets.all(8.0)` if not specified.
  final EdgeInsetsGeometry? margin;

  /// Maximum number of lines for the body and release notes text.
  ///
  /// If `null`, text is not truncated.
  final int? maxLines;

  /// How to handle text overflow for the body and release notes.
  ///
  /// Common values: [TextOverflow.ellipsis], [TextOverflow.fade].
  final TextOverflow? overflow;

  /// An optional builder that **replaces the entire card content**
  /// with a custom widget.
  ///
  /// See [UpgradeCardBuilder] for the callback signature.
  final UpgradeCardBuilder? builder;

  /// An optional builder that **replaces only the action buttons**
  /// of the default card layout.
  ///
  /// See [UpgradeCardActionsBuilder] for the callback signature.
  final UpgradeCardActionsBuilder? dialogActionsBuilder;

  /// Creates an [UpgradeCard].
  ///
  /// All parameters are optional and have sensible defaults.
  const UpgradeCard({
    super.key,
    this.config = const UpdateConfig(),
    this.source = const StoreUpdateSource(),
    this.margin,
    this.maxLines,
    this.overflow,
    this.builder,
    this.dialogActionsBuilder,
  });

  @override
  State<UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends State<UpgradeCard> {
  UpdateInfo? _info;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      // 1. Check Frequency (Skip if too soon)
      // Debug Always Show overrides this check.
      if (widget.config.checkInterval != null &&
          !widget.config.debugAlwaysShow) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheckedStr = prefs.getString(UpdateManager.kLastCheckedKey);
        if (lastCheckedStr != null) {
          final lastChecked = DateTime.tryParse(lastCheckedStr);
          if (lastChecked != null) {
            if (DateTime.now().difference(lastChecked) <
                widget.config.checkInterval!) {
              return; // Skip check
            }
          }
        }
      }

      // 2. Fetch
      UpdateInfo? info;
      try {
        info = await widget.source.fetchUpdateInfo();
      } catch (e) {
        if (!widget.config.debugAlwaysShow) {}
      }

      if (info == null) return;

      // 3. Debug Force vs Logic
      bool shouldShow = info.isUpdateAvailable;

      if (widget.config.debugAlwaysShow && kDebugMode) {
        shouldShow = true;
      }

      if (!shouldShow) return;

      // 4. Snooze Check
      if (!widget.config.debugAlwaysShow && !info.isCritical) {
        final prefs = await SharedPreferences.getInstance();
        final lastDismissedStr = prefs.getString(
          UpdateManager.kLastDismissedKey,
        );
        if (lastDismissedStr != null) {
          final lastDismissed = DateTime.tryParse(lastDismissedStr);
          if (lastDismissed != null) {
            if (DateTime.now().difference(lastDismissed) <
                widget.config.snoozeDuration) {
              return; // Snoozed
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _info = info;
          _visible = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _info == null) return const SizedBox.shrink();

    // Reusable Callbacks
    void onUpdate() => _performUpdate();
    void onLater() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        UpdateManager.kLastDismissedKey,
        DateTime.now().toIso8601String(),
      );
      if (mounted) setState(() => _visible = false);
    }

    // 1. Custom Builder (Full Replacement)
    if (widget.builder != null) {
      return widget.builder!(context, _info!, onUpdate, onLater);
    }

    final messages =
        widget.config.messages ??
        UpdaterMessages(languageCode: widget.config.languageCode);

    final appName = "App";

    final body = messages
        .message(UpdaterMessage.body)
        .replaceAll('{{appName}}', appName)
        .replaceAll(
          '{{currentInstalledVersion}}',
          _info!.currentVersion.toString(),
        )
        .replaceAll('{{latestVersion}}', _info!.latestVersion.toString());

    final isCupertino =
        widget.config.dialogStyle.resolved == UpgradeDialogStyle.cupertino;

    // 2. Custom Actions or Default
    List<Widget> actions;
    if (widget.dialogActionsBuilder != null) {
      actions = widget.dialogActionsBuilder!(
        context,
        _info!,
        onUpdate,
        onLater,
      );
    } else {
      actions = [
        if (widget.config.showIgnore)
          _buildButton(
            context,
            messages.message(UpdaterMessage.buttonTitleIgnore),
            isCupertino,
            onPressed: () {
              setState(() => _visible = false);
            },
            textStyle: widget.config.ignoreButtonTextStyle,
          ),
        if (widget.config.showLater)
          _buildButton(
            context,
            messages.message(UpdaterMessage.buttonTitleLater),
            isCupertino,
            onPressed: onLater,
            textStyle: widget.config.laterButtonTextStyle,
          ),
        if (isCupertino)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: onUpdate,
            child: Text(
              messages.message(UpdaterMessage.buttonTitleUpdate),
              style: widget.config.updateButtonTextStyle,
            ),
          )
        else
          FilledButton(
            onPressed: onUpdate,
            child: Text(
              messages.message(UpdaterMessage.buttonTitleUpdate).toUpperCase(),
              style: widget.config.updateButtonTextStyle,
            ),
          ),
      ];
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.config.showPrompt) ...[
          Text(
            messages.message(UpdaterMessage.title),
            style: isCupertino
                ? CupertinoTheme.of(context).textTheme.navTitleTextStyle
                : Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          body,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          style: isCupertino
              ? CupertinoTheme.of(context).textTheme.textStyle
              : null,
        ),
        if (widget.config.showReleaseNotes && _info!.releaseNotes != null) ...[
          const SizedBox(height: 8),
          Text(
            messages.message(UpdaterMessage.releaseNotes),
            style:
                (isCupertino
                        ? CupertinoTheme.of(context).textTheme.textStyle
                        : const TextStyle())
                    .copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            _info!.releaseNotes!,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
            style: isCupertino
                ? CupertinoTheme.of(context).textTheme.textStyle
                : null,
          ),
        ],
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
      ],
    );

    return Card(
      margin: widget.margin ?? const EdgeInsets.all(8.0),
      elevation: isCupertino ? 0 : 2,
      color: isCupertino ? CupertinoColors.systemGroupedBackground : null,
      child: Padding(padding: const EdgeInsets.all(16.0), child: content),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    bool isCupertino, {
    required VoidCallback onPressed,
    TextStyle? textStyle,
  }) {
    if (isCupertino) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onPressed: onPressed,
        child: Text(text, style: textStyle),
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        child: Text(text.toUpperCase(), style: textStyle),
      );
    }
  }

  Future<void> _performUpdate() async {
    if (_info == null) return;
    await UpdateController(config: widget.config).performUpdate(_info!);
  }
}
