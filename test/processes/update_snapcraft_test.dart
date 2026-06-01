import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateSnapcraftProcess', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync('release_update_snapcraft_test_');
    });

    tearDown(() {
      tempDirectory.deleteSync(recursive: true);
    });

    test('updates the configured snapcraft version', () async {
      File snapcraftFile = File('${tempDirectory.path}/snapcraft.yaml')
        ..writeAsStringSync('''
name: sample
version: 1.0.0
summary: Sample app
''');

      ReleaseProcessResult result = await const UpdateSnapcraftProcess().run(
        const Cmd(verbose: false),
        [
          _pubspecContent(snapcraftPath: snapcraftFile.path),
          NewVersion(version: Version.parse('1.2.3+4')),
        ],
      );

      expect(result, isA<ReleaseProcessResultSuccess<SnapcraftUpdated>>());

      String content = snapcraftFile.readAsStringSync();
      expect(content, contains('version: 1.2.3'));
      expect(content, contains('name: sample'));
    });

    test('cancels when snapcraft file does not exist', () async {
      ReleaseProcessResult result = await const UpdateSnapcraftProcess().run(
        const Cmd(verbose: false),
        [
          _pubspecContent(),
          NewVersion(version: Version.parse('1.2.3+4')),
        ],
      );

      expect(result, isA<ReleaseProcessResultCancelled>());
    });
  });
}

PubspecContent _pubspecContent({String? snapcraftPath}) => PubspecContent.fromYaml(
  {
    'version': '1.0.0',
    'repository': 'https://github.com/Skyost/DartRelease',
    if (snapcraftPath != null) 'release': {'snapcraftPath': snapcraftPath},
  },
  '',
);
