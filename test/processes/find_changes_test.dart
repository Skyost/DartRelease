import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

void main() {
  group('ConventionalCommitWithHash', () {
    for (final int length in [4, 7, 8, 12, 40, 64]) {
      test('preserves a $length-character hash and its conventional commit', () {
        final String hash = 'abcdef0123456789' * 4;
        final String abbreviation = hash.substring(0, length);

        final ConventionalCommitWithHash? commit = ConventionalCommitWithHash.tryParse('$abbreviation feat(cli)!: replace release flow');

        expect(commit, isNotNull);
        expect(commit!.hash, abbreviation);
        expect(commit.type, 'feat');
        expect(commit.scopes, ['cli']);
        expect(commit.description, 'replace release flow');
        expect(commit.isBreakingChange, isTrue);
      });
    }

    test('rejects missing or invalid hashes and missing messages', () {
      for (final String line in ['', 'feat: add release command', 'abcdef0', 'abcdef0 ', 'abcdef0z feat: invalid hash', ' abcdef0 feat: invalid prefix']) {
        expect(ConventionalCommitWithHash.tryParse(line), isNull, reason: line);
      }
    });
  });

  group('FindChangesProcess', () {
    test('reads changes with Git automatic hash lengths', () async {
      final ReleaseProcessResult result = await const FindChangesProcess().run(
        const _GitLogCmd(output: '2bdce524 chore(release): Updated release utility.\n'),
        [],
      );

      expect(result, isA<ReleaseProcessResultSuccess<ChangeLogEntry>>());
      final ChangeLogEntry entry = (result as ReleaseProcessResultSuccess<ChangeLogEntry>).value;
      expect(entry.changeCount, 1);
      expect(entry['chore']?.single.hash, '2bdce524');
      expect(entry.filter(ignoredHashes: ['2bdce524']).isEmpty, isTrue);
    });

    test('reports a failed Git log instead of succeeding with no changes', () async {
      final ReleaseProcessResult result = await const FindChangesProcess().run(
        const _GitLogCmd(exitCode: 128, error: 'fatal: invalid revision range'),
        [],
      );

      expect(result, isA<ReleaseProcessResultError>());
      expect((result as ReleaseProcessResultError).error.toString(), contains('fatal: invalid revision range'));
    });
  });

  group('ChangeLogEntry', () {
    test('parses conventional commits from git log output', () {
      ChangeLogEntry entry = ChangeLogEntry.parseGitLog('''
abcdef0 feat: add release command
abcdef1 fix(cli): handle missing changelog
not a conventional commit
abcdef2 docs: update readme
''');

      expect(entry.changeCount, 3);
      expect(entry.types, containsAll(['feat', 'fix', 'docs']));
      expect(entry['feat']?.single.description, 'add release command');
      expect(entry['fix']?.single.scopes, ['cli']);
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

/// Supplies Git output without modifying a repository or creating a release.
class _GitLogCmd extends Cmd {
  /// Commit log returned by Git.
  final String output;

  /// Exit status of the Git log command.
  final int exitCode;

  /// Diagnostic output from a failed Git log command.
  final String error;

  /// Creates a command runner with a known tag and configurable commit log.
  const _GitLogCmd({this.output = '', this.exitCode = 0, this.error = ''}) : super(verbose: false);

  @override
  Future<ProcessResult> run({required String executable, List<String> arguments = const []}) async {
    expect(executable, 'git');
    if (arguments.first == 'describe') {
      return ProcessResult(0, 0, '0.0.16\n', '');
    }
    expect(arguments, ['log', '0.0.16..HEAD', '--oneline']);
    return ProcessResult(0, exitCode, output, error);
  }
}
