import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

import '../support/recording_stdout.dart';

void main() {
  test('skips the Github release when no repository is configured', () async {
    ReleaseProcessResult result = await const CreateGithubReleaseProcess().run(
      const _FailingQuestionCmd(),
      [
        PubspecContent.fromYaml({'version': '1.0.0'}, ''),
        NewVersion(version: Version.parse('1.2.3')),
      ],
    );

    expect(result, isA<ReleaseProcessResultCancelled>());
  });

  for (final int status in [201, 404]) {
    test('only displays a Github release link after successful publication (HTTP $status)', () async {
      final directory = Directory.systemTemp.createTempSync('release_github_test_');
      addTearDown(() {
        directory.deleteSync(recursive: true);
      });
      final envFile = File('${directory.path}/.env')..writeAsStringSync('GITHUB_PAT=test-token\n');
      final output = RecordingStdout();
      final cmd = _GithubCmd();
      const url = 'https://github.com/Skyost/DartRelease/releases/tag/1.2.3';
      final result = await IOOverrides.runZoned(
        () => http.runWithClient(
          () => const CreateGithubReleaseProcess().run(cmd, [
            PubspecContent.fromYaml({'version': '1.0.0', 'repository': 'https://github.com/Skyost/DartRelease'}, ''),
            NewVersion(version: Version.parse('1.2.3')),
            const MarkdownEntryContent(content: '**Initial release**.\n'),
          ]),
          () => MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.toString(), 'https://api.github.com/repos/Skyost/DartRelease/releases');
            expect(jsonDecode(request.body)['body'], '**Initial release**.\n');
            return http.Response(jsonEncode({'html_url': url}), status);
          }),
        ),
        createFile: (path) {
          expect(path, '.env');
          return envFile;
        },
        stdout: () => output,
      );

      if (status == 201) {
        expect(result, isA<ReleaseProcessResultSuccess<GithubReleaseCreated>>());
        expect(output.output.toString(), contains('Github release: $url\n'));
        expect(cmd.fetchedTags, isTrue);
      } else {
        expect(result, isA<ReleaseProcessResultError>());
        expect(output.output.toString(), isNot(contains(url)));
        expect(cmd.fetchedTags, isFalse);
      }
    });
  }
}

class _GithubCmd extends Cmd {
  bool fetchedTags = false;

  _GithubCmd() : super(verbose: false);

  @override
  bool askQuestion(String question) => true;

  @override
  Future<ProcessResult> run({required String executable, List<String> arguments = const []}) async {
    expect(executable, 'git');
    expect(arguments, ['fetch', '--tags']);
    fetchedTags = true;
    return ProcessResult(0, 0, '', '');
  }
}

class _FailingQuestionCmd extends Cmd {
  const _FailingQuestionCmd() : super(verbose: false);

  @override
  bool askQuestion(String question) => throw StateError('Unexpected question: $question');
}
