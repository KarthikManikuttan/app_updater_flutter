import 'dart:io';

/// Defines the visual style of the update dialog.
enum UpgradeDialogStyle {
  /// Uses Material Design [AlertDialog].
  ///
  /// Best suited for Android apps.
  material,

  /// Uses Cupertino (iOS-style) [CupertinoAlertDialog].
  ///
  /// Best suited for iOS apps.
  cupertino,

  /// Automatically selects [material] on Android and [cupertino]
  /// on iOS based on [Platform.isIOS].
  ///
  /// This is the recommended option for cross-platform apps that
  /// want native-looking dialogs on both platforms.
  adaptive;

  /// Resolves [adaptive] to a concrete style based on the current
  /// platform.
  ///
  /// Returns [cupertino] if [Platform.isIOS] is `true`,
  /// otherwise returns [material].
  ///
  /// If the style is already [material] or [cupertino], it is
  /// returned unchanged.
  UpgradeDialogStyle get resolved {
    if (this == adaptive) {
      return Platform.isIOS ? cupertino : material;
    }
    return this;
  }
}

/// Enum for localization keys used in the package.
enum UpdaterMessage {
  /// Title of the update dialog.
  title,

  /// Body text of the update dialog.
  body,

  /// The "Update Now" button text.
  buttonTitleUpdate,

  /// The "Later" button text.
  buttonTitleLater,

  /// The "Ignore" button text.
  buttonTitleIgnore,

  /// Label for the release notes section.
  releaseNotes,

  /// A short prompt asking if the user wants to update.
  prompt,
}
