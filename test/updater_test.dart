import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:updater/src/models.dart';

void main() {
  group('SemverVersionParser', () {
    const parser = SemverVersionParser();

    test('parses simple version', () {
      final v = parser.parse('1.0.0');
      expect(v, Version(1, 0, 0));
    });

    test('parses version with v prefix', () {
      final v = parser.parse('v1.2.3');
      expect(v, Version(1, 2, 3));
    });

    test('parses partial version', () {
      final v = parser.parse('1.2');
      expect(v, Version(1, 2, 0));
    });
  });

  group('UpdateInfo', () {
    test('detects update available', () {
      final info = UpdateInfo(
        currentVersion: Version(1, 0, 0),
        latestVersion: Version(1, 0, 1),
      );
      expect(info.isUpdateAvailable, true);
    });

    test('detects no update available', () {
      final info = UpdateInfo(
        currentVersion: Version(1, 0, 0),
        latestVersion: Version(1, 0, 0),
      );
      expect(info.isUpdateAvailable, false);
    });
  });
}
