import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

void main() {
  group('WriteChangelogProcess', () {
    late Directory previousDirectory;
    late Directory tempDirectory;

    setUp(() {
      previousDirectory = Directory.current;
      tempDirectory = Directory.systemTemp.createTempSync('release_write_changelog_test_');
      Directory.current = tempDirectory;
    });

    tearDown(() {
      Directory.current = previousDirectory;
      tempDirectory.deleteSync(recursive: true);
    });

    test('writes a changelog entry and filters ignored scopes and types', () async {
      ChangeLogEntry changeLogEntry = ChangeLogEntry.parseGitLog('''
abcdef012345 feat: add release command
abcdef1 fix(internal): keep this internal
abcdef2 test: add coverage
''');

      ReleaseProcessResult result = await const WriteChangelogProcess().run(
        const Cmd(verbose: false),
        [
          _pubspecContent(),
          changeLogEntry,
          const IgnoredScopesTypesHashes(scopes: ['internal'], types: ['test'], hashes: []),
          NewVersion(version: Version.parse('1.2.3+4')),
        ],
      );

      expect(result, isA<ReleaseProcessResultSuccess<MarkdownEntryContent>>());

      File changelog = File('CHANGELOG.md');
      expect(changelog.existsSync(), isTrue);

      String content = changelog.readAsStringSync();
      expect(content, startsWith('# 📰 Changelog\n\n## v1.2.3'));
      expect(content, contains('add release command'));
      expect(content, contains('https://github.com/Skyost/DartRelease/commit/abcdef012345'));
      expect(content, isNot(contains('keep this internal')));
      expect(content, isNot(contains('add coverage')));
    });

    test('cancels when required previous process values are missing', () async {
      ReleaseProcessResult result = await const WriteChangelogProcess().run(
        const Cmd(verbose: false),
        [_pubspecContent()],
      );

      expect(result, isA<ReleaseProcessResultCancelled>());
    });

    test('writes a fallback when all commits are ignored', () async {
      final result = await const WriteChangelogProcess().run(const Cmd(verbose: false), [
        _pubspecContent(),
        ChangeLogEntry.parseGitLog('abcdef0 test: Add coverage.'),
        const IgnoredScopesTypesHashes(scopes: [], types: ['test'], hashes: []),
        NewVersion(version: Version.parse('1.2.3')),
      ]);

      final content = (result as ReleaseProcessResultSuccess<MarkdownEntryContent>).value.content;
      expect(content, 'Aucune note trouvée pour cette release.\n');
      expect(File('CHANGELOG.md').readAsStringSync(), contains(content));
    });

    test('renders a configurable fallback without a Github repository', () async {
      final result = await const WriteChangelogProcess().run(const Cmd(verbose: false), [
        PubspecContent.fromYaml({
          'version': '1.0.0',
          'release': {
            'changelog': {
              'entry': {'empty': 'No notes for {{ version }}.'},
            },
          },
        }, ''),
        ChangeLogEntry(),
        const IgnoredScopesTypesHashes(scopes: [], types: [], hashes: []),
        NewVersion(version: Version.parse('1.2.3')),
      ]);

      final content = (result as ReleaseProcessResultSuccess<MarkdownEntryContent>).value.content;
      expect(content, 'No notes for 1.2.3.\n');
      expect(File('CHANGELOG.md').readAsStringSync(), contains(content));
    });
  });
}

PubspecContent _pubspecContent() => PubspecContent.fromYaml(
  {
    'version': '1.0.0',
    'repository': 'https://github.com/Skyost/DartRelease',
  },
  '',
);
