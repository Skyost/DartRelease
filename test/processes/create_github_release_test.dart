import 'package:pub_semver/pub_semver.dart';
import 'package:release/release.dart';
import 'package:test/test.dart';

void main() {
  test('skips the Github release when no repository is configured', () async {
    ReleaseProcessResult result = await const CreateGithubReleaseProcess().run(
      _FailingQuestionCmd(),
      [
        PubspecContent.fromYaml({'version': '1.0.0'}, ''),
        NewVersion(version: Version.parse('1.2.3')),
      ],
    );

    expect(result, isA<ReleaseProcessResultCancelled>());
  });
}

class _FailingQuestionCmd extends Cmd {
  const _FailingQuestionCmd() : super(verbose: false);

  @override
  bool askQuestion(String question) => throw StateError('Unexpected question: $question');
}
