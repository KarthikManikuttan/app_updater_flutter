import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models.dart';

/// An [UpdateSource] that checks the **Google Play Store** (Android)
/// or **Apple App Store** (iOS) for updates.
///
/// On Android this uses a multi-strategy approach:
///
/// 1. **Google Play In-App Update API** — the official way to detect
///    updates. May fail for side-loaded or debug builds.
/// 2. **HTML Scraping** — as a fallback, scrapes the Play Store page
///    for the latest version string and release notes using several
///    strategies (JSON-LD, script regex, mobile UA, heuristic delta).
///
/// On iOS it queries the iTunes Lookup API using the app's bundle ID.
///
/// This is the **default** source used when no [UpdateSource] is
/// specified.
class StoreUpdateSource implements UpdateSource {
  /// The parser used to convert raw version strings to [Version].
  ///
  /// Defaults to [SemverVersionParser].
  final VersionParser parser;

  /// An optional iOS App ID override.
  ///
  /// If `null`, the bundle ID from `package_info_plus` is used
  /// to look up the app on iTunes.
  final String? iosAppId;

  /// Creates a [StoreUpdateSource].
  ///
  /// - [parser] — version string parser. Defaults to [SemverVersionParser].
  /// - [iosAppId] — optional iOS App ID, used if bundle-ID lookup
  ///   is not sufficient.
  const StoreUpdateSource({
    this.parser = const SemverVersionParser(),
    this.iosAppId,
  });

  /// Fetches update information from the platform store.
  ///
  /// Returns an [UpdateInfo] on success, or `null` if the store
  /// is unreachable, the response is invalid, or the app is not
  /// listed.
  @override
  Future<UpdateInfo?> fetchUpdateInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final Version currentVersion = parser.parse(packageInfo.version);

      if (Platform.isAndroid) {
        AppUpdateInfo? inAppInfo;
        try {
          inAppInfo = await InAppUpdate.checkForUpdate();
        } catch (e) {}

        // Scraping Logic (Best Effort)
        String? scrapedNotes;
        String? scrapedVersionStr;

        try {
          final url = Uri.parse(
            'https://play.google.com/store/apps/details?id=${packageInfo.packageName}&hl=en&gl=US',
          );

          // Switch to Mobile User-Agent
          // This often ensures a simpler HTML structure or one that matches the "About" screen data better.
          final response = await http.get(
            url,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
            },
          );

          if (response.statusCode == 200) {
            final html = response.body;

            // Strategy 1: Specific Google Play Keys (Expanded Range & Flexible Brackets)
            // Pattern: "140":[[["1.0.3"]]] OR "140":["1.0.3"]
            {
              final keyPattern = RegExp(
                r'["'
                '](?:1|2|3|4|5|6|7|8|9|10|140|141|142|143|144|145|146|147|148|149|150)["'
                ']:s*[{1,5}["' // Match 1 to 5 opening brackets
                ']([^"'
                '<]+)["'
                ']',
                caseSensitive: false,
              );
              final matches = keyPattern.allMatches(html);
              for (final match in matches) {
                final rawVer = match.group(1);
                if (rawVer != null &&
                    RegExp(r'^\d+(\.\d+)+').hasMatch(rawVer)) {
                  // Basic heuristic: Is it "newer" or at least valid?
                  // For now, accept the first valid one, or maybe the highest?
                  // Let's take the first valid one.
                  scrapedVersionStr = rawVer;
                  break;
                }
              }
            }

            // Strategy 1.5: Deep Bracket Pattern (Highest Confidence)
            // Unkeyed generic structure often used for the main version: [[["1.0.3"]]]
            if (scrapedVersionStr == null) {
              final deepBracketPattern = RegExp(
                r'\[\s*\[\s*\[\s*["'
                '](d+.d+.d+)["'
                ']s*]s*]s*]',
              );
              final vMatch = deepBracketPattern.firstMatch(html);
              if (vMatch != null) {
                scrapedVersionStr = vMatch.group(1);
              }
            }

            // Strategy 2: Bracket Pattern (Regional variations)
            // Pattern: ]]],"1.0.3"
            if (scrapedVersionStr == null) {
              final bracketPattern = RegExp(
                r'\]\]\],\s*["'
                '](d+.d+.d+)["'
                ']',
              );
              final vMatch = bracketPattern.firstMatch(html);
              if (vMatch != null) {
                scrapedVersionStr = vMatch.group(1);
              }
            }

            // Strategy 3: JSON-LD (Standard SEO tag)
            if (scrapedVersionStr == null) {
              final jsonLdPattern = RegExp(
                r'["'
                ']softwareVersion["'
                ']s*:s*["'
                ']([^"'
                '<]+)["'
                ']',
                caseSensitive: false,
              );
              var vMatch = jsonLdPattern.firstMatch(html);
              if (vMatch != null) scrapedVersionStr = vMatch.group(1);
            }

            // Strategy 4: Raw Script Regex (AF_initDataCallbackish)
            if (scrapedVersionStr == null) {
              // Look for the specific "Version" label in text followed by a number.
              final labelPattern = RegExp(
                r'Version.{0,200}(\d+\.\d+\.\d+)',
                caseSensitive: false,
                dotAll: true,
              );
              final vMatch = labelPattern.firstMatch(html);
              if (vMatch != null) scrapedVersionStr = vMatch.group(1);
            }

            // Strategy 6: Heuristic - Smallest Delta > Current
            // If all strict keys failed, look at ALL version-like strings found in HTML.
            // Valid candidates are > currentVersion.
            // The "winner" is the one closest to currentVersion (smallest delta).
            // This filters out "Similar Apps" (e.g. 10.5.3) which are usually much higher/different.
            if (scrapedVersionStr == null) {
              final allVersionsMatch = RegExp(
                r'\d+\.\d+\.\d+',
              ).allMatches(html);
              Version? bestCandidate;

              for (var m in allVersionsMatch) {
                final raw = m.group(0);
                if (raw == null) continue;

                try {
                  final candidate = parser.parse(raw);
                  if (candidate > currentVersion) {
                    // It's a possible update.
                    if (bestCandidate == null) {
                      bestCandidate = candidate;
                    } else {
                      // Check if this one is "closer" to current than the best so far.
                      // We want the smallest upgrade (e.g. 1.0.2 -> 1.0.3 is better than 1.0.2 -> 5.0.0)
                      if (candidate < bestCandidate) {
                        bestCandidate = candidate;
                      }
                    }
                  }
                } catch (_) {}
              }

              if (bestCandidate != null) {
                scrapedVersionStr = bestCandidate.toString();
              }
            }

            // Fallback: Release Notes
            final whatsNewPattern = RegExp(
              r'''What's new.*?itemprop="description">(.*?)<\/div>''',
              caseSensitive: false,
              dotAll: true,
            );
            var match = whatsNewPattern.firstMatch(html);
            if (match != null) {
              scrapedNotes = match
                  .group(1)
                  ?.replaceAll('<br>', '\n')
                  .replaceAll(RegExp(r'<[^>]*>'), '')
                  .trim();
            } else {
              // Fallback: Main Description
              final descriptionPattern = RegExp(
                r'''itemprop="description">(.*?)<\/div>''',
                caseSensitive: false,
                dotAll: true,
              );
              match = descriptionPattern.firstMatch(html);
              if (match != null) {
                scrapedNotes = match
                    .group(1)
                    ?.replaceAll('<br>', '\n')
                    .replaceAll(RegExp(r'<[^>]*>'), '')
                    .trim();
                if (scrapedNotes != null && scrapedNotes.length > 500) {
                  scrapedNotes = "${scrapedNotes.substring(0, 500)}...";
                }
              }
            }
          }
        } catch (e) {}

        // Decision Logic
        if (inAppInfo != null &&
            inAppInfo.updateAvailability ==
                UpdateAvailability.updateAvailable) {
          return UpdateInfo(
            currentVersion: currentVersion,
            // Dummy increment since native API doesn't give remote version
            latestVersion: scrapedVersionStr != null
                ? parser.parse(scrapedVersionStr)
                : Version(
                    currentVersion.major,
                    currentVersion.minor,
                    currentVersion.patch + 1,
                  ),
            releaseNotes: scrapedNotes,
            platformData: inAppInfo,
          );
        } else if (inAppInfo != null) {
          // No update via Native API
          // Check scraped version (Handle Fallback)
          Version latest = currentVersion;
          if (scrapedVersionStr != null) {
            try {
              final scrapedVer = parser.parse(scrapedVersionStr);
              if (scrapedVer > currentVersion) {
                latest = scrapedVer;
              }
            } catch (_) {}
          }

          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latest,
            releaseNotes: scrapedNotes,
            platformData: inAppInfo,
          );
        }

        // Fallback: If InAppUpdate failed (e.g. side-loaded), return scraped info
        // This ensures debugAlwaysShow can still display scraped notes/version.
        Version latest = currentVersion;
        if (scrapedVersionStr != null) {
          try {
            final scrapedVer = parser.parse(scrapedVersionStr);
            if (scrapedVer > currentVersion) latest = scrapedVer;
          } catch (_) {}
        }
        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latest,
          releaseNotes: scrapedNotes,
          // platformData is null here
        );
      } else if (Platform.isIOS) {
        final bundleId = packageInfo.packageName;
        final url = Uri.parse(
          'https://itunes.apple.com/lookup?bundleId=$bundleId',
        );
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['resultCount'] > 0) {
            final result = json['results'][0];
            final storeVersionStr = result['version'] as String;
            final trackViewUrl = result['trackViewUrl'] as String;
            final releaseNotes = result['releaseNotes'] as String?;

            final storeVersion = parser.parse(storeVersionStr);

            return UpdateInfo(
              currentVersion: currentVersion,
              latestVersion: storeVersion,
              updateUrl: trackViewUrl,
              releaseNotes: releaseNotes,
            );
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
