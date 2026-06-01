import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('UpdateFlatpakProcess', () {
    late Directory tempDirectory;

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync('release_update_flatpak_test_');
    });

    tearDown(() {
      tempDirectory.deleteSync(recursive: true);
    });

    test('prepends a release entry with changelog content', () async {
      File flatpakFile = File('${tempDirectory.path}/app.metainfo.xml')
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<component>
  <id>com.example.Sample</id>
  <releases>
    <release version="1.0.0" date="2025-01-01" />
  </releases>
</component>
''');
      ChangeLogEntry changeLogEntry = ChangeLogEntry.parseGitLog('''
abcdef0 feat: add release command
abcdef1 fix(internal): keep this internal
abcdef2 test: add coverage
''');

      ReleaseProcessResult result = await const UpdateFlatpakProcess().run(
        const Cmd(verbose: false),
        [
          _pubspecContent(flatpakPath: flatpakFile.path),
          changeLogEntry,
          const IgnoredScopesTypesHashes(scopes: ['internal'], types: ['test'], hashes: []),
          NewVersion(version: Version.parse('1.2.3+4')),
        ],
      );

      expect(result, isA<ReleaseProcessResultSuccess<FlatpakUpdated>>());

      XmlDocument document = XmlDocument.parse(flatpakFile.readAsStringSync());
      List<XmlElement> releases = document.findAllElements('release').toList();
      expect(releases, hasLength(2));
      expect(releases.first.getAttribute('version'), '1.2.3');
      expect(releases.first.findElements('url').single.innerText, 'https://github.com/Skyost/DartRelease/releases/tag/1.2.3');
      expect(releases.first.innerXml, contains('add release command'));
      expect(releases.first.innerXml, isNot(contains('keep this internal')));
      expect(releases.first.innerXml, isNot(contains('add coverage')));
      expect(releases.last.getAttribute('version'), '1.0.0');
    });

    test('cancels when flatpak file does not exist', () async {
      ReleaseProcessResult result = await const UpdateFlatpakProcess().run(
        const Cmd(verbose: false),
        [
          _pubspecContent(),
          const IgnoredScopesTypesHashes(scopes: [], types: [], hashes: []),
          NewVersion(version: Version.parse('1.2.3+4')),
        ],
      );

      expect(result, isA<ReleaseProcessResultCancelled>());
    });
  });
}

PubspecContent _pubspecContent({String? flatpakPath}) => PubspecContent.fromYaml(
  {
    'version': '1.0.0',
    'repository': 'https://github.com/Skyost/DartRelease',
    if (flatpakPath != null) 'release': {'flatpakPath': flatpakPath},
  },
  '',
);
