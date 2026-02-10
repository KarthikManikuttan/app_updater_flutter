import 'dart:async';

import 'package:pub_semver/pub_semver.dart';
export 'package:pub_semver/pub_semver.dart';

// ---------------- Model ----------------

/// Contains all information about an available (or unavailable) update.
///
/// This is the main data object passed to builders and callbacks
/// throughout the Updater package.
class UpdateInfo {
  /// The version currently installed on the user's device.
  ///
  /// Parsed from `package_info_plus` using [VersionParser].
  final Version currentVersion;

  /// The latest version available on the store or remote source.
  final Version latestVersion;

  /// Human-readable release notes for [latestVersion].
  ///
  /// May be `null` if the source did not provide any notes
  /// (e.g., Play Store scraping failed or the JSON endpoint
  /// omitted the field).
  final String? releaseNotes;

  /// A direct URL to the store listing or download page.
  ///
  /// On iOS this is the `trackViewUrl` from the iTunes API.
  /// On Android it defaults to `market://details?id=<packageName>`
  /// and falls back to this URL if the market intent fails.
  /// May be `null` if the source did not provide one.
  final String? updateUrl;

  /// Whether this update is marked as critical / mandatory.
  ///
  /// When `true`, the default dialog hides the "Later" button
  /// and prevents dismissal via the back button (unless
  /// overridden by [UpdateConfig.canPopScope]).
  final bool isCritical;

  /// Platform-specific metadata returned by the native update API.
  ///
  /// On Android this is an `AppUpdateInfo` instance from the
  /// `in_app_update` plugin. On iOS or when using [JsonUpdateSource]
  /// this will be `null`.
  final dynamic platformData;

  /// Creates an [UpdateInfo] instance.
  ///
  /// [currentVersion] and [latestVersion] are required.
  /// All other fields are optional.
  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    this.releaseNotes,
    this.updateUrl,
    this.isCritical = false,
    this.platformData,
  });

  /// Returns `true` when [latestVersion] is strictly greater
  /// than [currentVersion] according to Semantic Versioning.
  bool get isUpdateAvailable => latestVersion > currentVersion;
}

// ---------------- Strategies ----------------

/// The data-source strategy used to fetch update information.
///
/// Implement this interface to create a custom update source.
/// The package ships with two built-in implementations:
///
/// * [StoreUpdateSource] — Checks the Google Play Store (Android)
///   or Apple App Store (iOS).
/// * [JsonUpdateSource] — Checks a custom JSON endpoint.
abstract class UpdateSource {
  /// Fetches update information from the remote source.
  ///
  /// Returns an [UpdateInfo] if the lookup succeeds, or `null`
  /// if the source is unreachable or the response is invalid.
  Future<UpdateInfo?> fetchUpdateInfo();
}

/// Strategy for parsing raw version strings into [Version] objects.
///
/// The default implementation is [SemverVersionParser], which
/// handles common variations like `"v1.0.0"` and `"1.0"`.
abstract class VersionParser {
  /// Parses [versionString] into a [Version].
  ///
  /// Implementations should handle edge cases gracefully
  /// (e.g., missing patch segment, leading `v` prefix).
  Version parse(String versionString);
}

// ---------------- Implementations ----------------

/// Default [VersionParser] that uses Semantic Versioning.
///
/// Handles common real-world edge cases:
/// * Leading `v` or `V` prefix — `"v1.2.3"` → `1.2.3`.
/// * Missing patch segment — `"1.2"` → `"1.2.0"`.
///
/// If parsing fails entirely, returns `Version(0, 0, 0)` so
/// the update check can continue without crashing.
class SemverVersionParser implements VersionParser {
  /// Creates a const [SemverVersionParser].
  const SemverVersionParser();

  /// Parses [versionString] into a [Version].
  ///
  /// Cleans the input by stripping a leading `v`/`V` and
  /// appending `.0` when only major.minor is provided.
  ///
  /// Returns `Version(0, 0, 0)` on any parse failure.
  @override
  Version parse(String versionString) {
    try {
      // Clean up common issues like "1.0" -> "1.0.0" or "v1.0.0" -> "1.0.0"
      String clean = versionString.trim();
      if (clean.startsWith('vV')) clean = clean.substring(1);

      // Handle "1.0" cases
      if (RegExp(r'^\d+\.\d+$').hasMatch(clean)) {
        clean += '.0';
      }

      return Version.parse(clean);
    } catch (e) {
      return Version(0, 0, 0);
    }
  }
}
