import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../models.dart';

/// An [UpdateSource] that fetches update information from a
/// custom JSON endpoint.
///
/// Use this for **private, enterprise, or self-hosted** apps that
/// are not listed on the public stores.
///
/// The endpoint must return a JSON object with the following shape:
///
/// ```json
/// {
///   "latestVersion": "1.2.3",
///   "url": "https://example.com/download",
///   "releaseNotes": "Bug fixes and performance improvements.",
///   "critical": false
/// }
/// ```
///
/// | Key              | Type     | Required | Description                          |
/// |------------------|----------|----------|--------------------------------------|
/// | `latestVersion`  | `String` | ✅       | The latest available version.        |
/// | `url`            | `String` | ❌       | Direct download / store URL.         |
/// | `releaseNotes`   | `String` | ❌       | Human-readable changelog.            |
/// | `critical`       | `bool`   | ❌       | Whether the update is mandatory.     |
class JsonUpdateSource implements UpdateSource {
  /// The URL of the JSON endpoint to fetch update info from.
  ///
  /// Must return a JSON object matching the format described above.
  final String url;

  /// The parser used to convert the `latestVersion` string to a
  /// [Version] object. Defaults to [SemverVersionParser].
  final VersionParser parser;

  /// Optional HTTP headers to include in the request.
  ///
  /// Useful for authentication (e.g., `Authorization: Bearer ...`)
  /// or custom API keys.
  final Map<String, String>? headers;

  /// Creates a [JsonUpdateSource].
  ///
  /// - [url] — **(required)** The JSON endpoint URL.
  /// - [parser] — version string parser. Defaults to [SemverVersionParser].
  /// - [headers] — optional HTTP headers.
  const JsonUpdateSource({
    required this.url,
    this.parser = const SemverVersionParser(),
    this.headers,
  });

  /// Fetches update information from the JSON endpoint at [url].
  ///
  /// Returns an [UpdateInfo] on success, or `null` if the request
  /// fails or the response cannot be parsed.
  @override
  Future<UpdateInfo?> fetchUpdateInfo() async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // Expected format:
        // {
        //   "latestVersion": "1.2.3",
        //   "url": "https://...",
        //   "releaseNotes": "...",
        //   "critical": false
        // }

        final latestVersionStr = json['latestVersion'] as String;
        final updateUrl = json['url'] as String?;
        final releaseNotes = json['releaseNotes'] as String?;
        final isCritical = json['critical'] as bool? ?? false;

        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = parser.parse(packageInfo.version);
        final latestVersion = parser.parse(latestVersionStr);

        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          updateUrl: updateUrl,
          releaseNotes: releaseNotes,
          isCritical: isCritical,
        );
      }
    } catch (e) {
      debugPrint("error $e");
    }
    return null;
  }
}
