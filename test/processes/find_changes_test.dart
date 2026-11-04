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
    for (final bool tagExists in [false, true]) {
      test('suggests 0.1.0 after ${tagExists ? 'finding' : 'creating'} the initial tag', () async {
        final cmd = _InitialReleaseCmd(tagExists: tagExists);
        final result = await const FindChangesProcess().run(cmd, []);
        final entry = (result as ReleaseProcessResultSuccess<ChangeLogEntry>).value;

        expect(entry.isInitialRelease, isTrue);
        expect(entry.filter(ignoredTypes: ['chore']).isInitialRelease, isTrue);
        final versionResult = await const NewVersionProcess().run(cmd, [
          PubspecContent.fromYaml({'version': '1.0.0'}, ''),
          entry,
        ]);
        expect((versionResult as ReleaseProcessResultSuccess<NewVersion>).value.version.toString(), '0.1.0');
      });
    }

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

    test('increments the build number for the initial release', () {
      final entry = ChangeLogEntry(isInitialRelease: true);

      expect(entry.bumpVersion(Version.parse('0.0.1+4')).toString(), '0.1.0+5');
    });

    test('bumps minor, resets patch, and increments build number for breaking changes', () {
      ChangeLogEntry entry = ChangeLogEntry.parseGitLog('abcdef0 feat!: replace release flow');

      Version version = entry.bumpVersion(Version.parse('1.2.3+4'));

      expect(version.toString(), '1.3.0+5');
    });
  });
}

class _InitialReleaseCmd extends Cmd {
  bool tagExists;

  _InitialReleaseCmd({required this.tagExists}) : super(verbose: false);

  @override
  bool askQuestion(String question) => true;

  @override
  String? readLine() => 'Y';

  @override
  Future<ProcessResult> run({required String executable, List<String> arguments = const []}) async {
    expect(executable, 'git');
    if (arguments.first == 'describe') {
      return ProcessResult(0, tagExists ? 0 : 128, tagExists ? '0.0.0\n' : '', '');
    }
    if (arguments.first == 'tag') {
      expect(arguments, ['tag', '-a', '0.0.0', 'abcdef0', '-m', 'First commit.']);
      tagExists = true;
      return ProcessResult(0, 0, '', '');
    }
    expect(arguments.first, 'log');
    expect(arguments, tagExists ? ['log', '0.0.0..HEAD', '--oneline'] : ['log', '--oneline', '--reverse']);
    return ProcessResult(0, 0, 'abcdef0 chore: Initial commit.\n', '');
  }
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
