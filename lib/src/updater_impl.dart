import 'package:flutter/material.dart';

import 'models.dart';
import 'sources/store_source.dart';
import 'update_config.dart';
import 'update_manager.dart';

/// Signature for a builder that **replaces the entire update dialog**
/// with a custom widget (e.g., a BottomSheet or full-screen page).
///
/// The builder receives:
///
/// - [context] — The [BuildContext] used to build the widget.
/// - [info] — The [UpdateInfo] containing the current version,
///   latest version, release notes, and criticality flag.
/// - [update] — A [VoidCallback] that, when called, redirects the
///   user to the store listing (Play Store / App Store) or the
///   custom update URL.
/// - [later] — A [VoidCallback] that, when called, snoozes the
///   update prompt for the duration configured in
///   [UpdateConfig.snoozeDuration] and closes the dialog.
typedef UpdateDialogBuilder =
    Widget Function(
      BuildContext context,
      UpdateInfo info,
      VoidCallback update,
      VoidCallback later,
    );

/// Signature for a builder that **replaces only the action buttons**
/// of the default update dialog.
///
/// Must return a `List<Widget>` of action buttons.
///
/// The builder receives:
///
/// - [context] — The [BuildContext] used to build the actions.
/// - [info] — The [UpdateInfo] containing version & release notes.
/// - [update] — A [VoidCallback] to trigger the store redirect.
/// - [later] — A [VoidCallback] to snooze the update prompt.
typedef UpdateActionsBuilder =
    List<Widget> Function(
      BuildContext context,
      UpdateInfo info,
      VoidCallback update,
      VoidCallback later,
    );

///
/// Provides a static [init] method to start checking for app updates
/// from the Play Store, App Store, or a custom JSON endpoint.
///
/// Example:
/// ```dart
/// Updater.init(
///   context: context,
///   config: UpdateConfig(checkInterval: Duration(days: 1)),
/// );
/// ```
class Updater {
  /// Initializes the update checker and performs an immediate check.
  ///
  /// This sets up a [WidgetsBindingObserver] so updates are also
  /// re-checked every time the app resumes from the background.
  ///
  /// **Parameters:**
  ///
  /// - [context] — The [BuildContext] used to display the update dialog.
  ///   Must be from a widget that is currently mounted in the tree.
  ///
  /// - [source] — The data source to fetch update info from.
  ///   Defaults to [StoreUpdateSource], which checks the Play Store
  ///   (Android) or App Store (iOS). Use [JsonUpdateSource] for a
  ///   custom endpoint.
  ///
  /// - [config] — Configuration options such as check interval, snooze
  ///   duration, dialog style, and native update flags.
  ///   See [UpdateConfig] for all available options.
  ///
  /// - [onUpdateShown] — Called when the update dialog is presented
  ///   to the user.
  ///
  /// - [onUpdateIgnored] — Called when the user taps "Later" or
  ///   dismisses the update dialog.
  ///
  /// - [onUpdateAccepted] — Called when the user taps "Update" and
  ///   is redirected to the store.
  ///
  /// - [onError] — Called when the update check fails. Receives the
  ///   error message as a [String].
  ///
  /// - [builder] — An optional [UpdateDialogBuilder] that replaces
  ///   the entire default dialog with a custom widget.
  ///
  /// - [dialogActionsBuilder] — An optional [UpdateActionsBuilder]
  ///   that replaces only the action buttons of the default dialog.
  ///
  /// **Returns** a [VoidCallback] that, when called, removes the
  /// lifecycle observer. Call this in your widget's `dispose()` to
  /// prevent memory leaks.
  ///
  /// Example:
  /// ```dart
  /// late final VoidCallback _disposeUpdater;
  ///
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _disposeUpdater = Updater.init(context: context);
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   _disposeUpdater();
  ///   super.dispose();
  /// }
  /// ```
  static VoidCallback init({
    required BuildContext context,
    UpdateSource source = const StoreUpdateSource(),
    UpdateConfig config = const UpdateConfig(),
    VoidCallback? onUpdateShown,
    VoidCallback? onUpdateIgnored,
    VoidCallback? onUpdateAccepted,
    Function(String error)? onError,
    UpdateDialogBuilder? builder,
    UpdateActionsBuilder? dialogActionsBuilder,
  }) {
    final manager = UpdateManager(
      source: source,
      config: config,
      onUpdateShown: onUpdateShown,
      onUpdateIgnored: onUpdateIgnored,
      onUpdateAccepted: onUpdateAccepted,
      onError: onError,
    );

    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      manager.check(
        context,
        builder: builder,
        dialogActionsBuilder: dialogActionsBuilder,
      );
    });

    // Lifecycle
    final lifecycle = _UpdaterLifecycle(
      manager,
      context,
      builder,
      dialogActionsBuilder,
    );
    WidgetsBinding.instance.addObserver(lifecycle);

    return () {
      WidgetsBinding.instance.removeObserver(lifecycle);
    };
  }
}

class _UpdaterLifecycle extends WidgetsBindingObserver {
  final UpdateManager manager;
  final BuildContext context;
  final UpdateDialogBuilder? builder;
  final UpdateActionsBuilder? dialogActionsBuilder;

  _UpdaterLifecycle(
    this.manager,
    this.context,
    this.builder,
    this.dialogActionsBuilder,
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      manager.check(
        context,
        builder: builder,
        dialogActionsBuilder: dialogActionsBuilder,
      );
    }
  }
}

/// A widget that initializes the [Updater] when it is inserted into
/// the widget tree and automatically cleans up when it is removed.
///
/// This is the **declarative** alternative to calling [Updater.init]
/// manually in `initState` / `dispose`. Wrap your app or any subtree
/// with this widget to enable automatic update checks.
///
/// Example:
/// ```dart
/// UpdaterListener(
///   config: UpdateConfig(checkInterval: Duration(hours: 1)),
///   onUpdateShown: () => analytics.log('update_shown'),
///   child: MaterialApp(home: HomeScreen()),
/// )
/// ```
class UpdaterListener extends StatefulWidget {
  /// The widget below this widget in the tree.
  ///
  /// The [UpdaterListener] itself is invisible — it simply wraps
  /// [child] and adds the update-checking behaviour.
  final Widget child;

  /// The data source to fetch update information from.
  ///
  /// Defaults to [StoreUpdateSource] (Play Store / App Store).
  /// Use [JsonUpdateSource] for a custom endpoint.
  final UpdateSource source;

  /// Configuration for the update checker.
  ///
  /// Controls check intervals, snooze duration, dialog style,
  /// language, native update flags, and more.
  /// See [UpdateConfig] for all available options.
  final UpdateConfig config;

  /// Called when the update dialog is presented to the user.
  final VoidCallback? onUpdateShown;

  /// Called when the user dismisses or taps "Later" on the
  /// update dialog.
  final VoidCallback? onUpdateIgnored;

  /// Called when the user taps "Update" and is redirected
  /// to the store listing.
  final VoidCallback? onUpdateAccepted;

  /// Called when the update check fails.
  ///
  /// Receives the error message as a [String].
  final Function(String error)? onError;

  /// An optional builder that **replaces the entire default dialog**
  /// with a custom widget.
  ///
  /// See [UpdateDialogBuilder] for the full callback signature and
  /// parameter documentation.
  final UpdateDialogBuilder? builder;

  /// An optional builder that **replaces only the action buttons**
  /// of the default dialog.
  ///
  /// See [UpdateActionsBuilder] for the full callback signature and
  /// parameter documentation.
  final UpdateActionsBuilder? dialogActionsBuilder;

  /// Creates an [UpdaterListener] that automatically checks for
  /// updates when mounted and cleans up when disposed.
  ///
  /// The [child] is required — it is the widget tree that this
  /// listener wraps.
  ///
  /// All other parameters are optional and have sensible defaults:
  ///
  /// - [source] defaults to [StoreUpdateSource] (Play Store / App Store).
  /// - [config] defaults to [UpdateConfig] with default values.
  /// - [onUpdateShown] fires when the update dialog appears.
  /// - [onUpdateIgnored] fires when the user taps "Later".
  /// - [onUpdateAccepted] fires when the user taps "Update".
  /// - [onError] fires on any error, with the error message as a [String].
  /// - [builder] replaces the entire dialog — see [UpdateDialogBuilder].
  /// - [dialogActionsBuilder] replaces only the action buttons —
  ///   see [UpdateActionsBuilder].
  const UpdaterListener({
    super.key,
    required this.child,
    this.source = const StoreUpdateSource(),
    this.config = const UpdateConfig(),
    this.onUpdateShown,
    this.onUpdateIgnored,
    this.onUpdateAccepted,
    this.onError,
    this.builder,
    this.dialogActionsBuilder,
  });

  @override
  State<UpdaterListener> createState() => _UpdaterListenerState();
}

class _UpdaterListenerState extends State<UpdaterListener> {
  VoidCallback? _dispose;

  @override
  void initState() {
    super.initState();
    _dispose = Updater.init(
      context: context,
      source: widget.source,
      config: widget.config,
      onUpdateShown: widget.onUpdateShown,
      onUpdateIgnored: widget.onUpdateIgnored,
      onUpdateAccepted: widget.onUpdateAccepted,
      onError: widget.onError,
      builder: widget.builder,
      dialogActionsBuilder: widget.dialogActionsBuilder,
    );
  }

  @override
  void dispose() {
    _dispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
