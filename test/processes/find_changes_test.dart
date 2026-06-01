import 'package:pub_semver/pub_semver.dart';
import 'package:release/src/processes/find_changes.dart';
import 'package:test/test.dart';

void main() {
  group('ChangeLogEntry', () {
    test('parses conventional commits from git log output', () {
      ChangeLogEntry entry = ChangeLogEntry.parseGitLog('''
abcdef0 feat: add release command
abcdef1 fix(cli): handle missing changelog
not a conventional commit
abcdef2 docs: update readme
''');

      expect(entry.changeCount, 3);
      expect(entry.subEntries.keys, containsAll(['feat', 'fix', 'docs']));
      expect(entry.subEntries['feat']?.single.description, 'add release command');
      expect(entry.subEntries['fix']?.single.scopes, ['cli']);
    });

    test('bumps patch and build number without breaking changes', () {
      ChangeLogEntry entry = ChangeLogEntry.parseGitLog('abcdef0 fix: handle missing changelog');

      Version version = entry.bumpVersion(Version.parse('1.2.3+4'));

      expect(version.toString(), '1.2.4+5');
    });

    test('bumps minor, resets patch, and increments build number for breaking changes', () {
      ChangeLogEntry entry = ChangeLogEntry.parseGitLog('abcdef0 feat!: replace release flow');

      Version version = entry.bumpVersion(Version.parse('1.2.3+4'));

      expect(version.toString(), '1.3.0+5');
    });
  });
}
