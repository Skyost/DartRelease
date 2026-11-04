import 'dart:io';

import 'package:release/release.dart';
import 'package:test/test.dart';

import '../support/recording_stdout.dart';

void main() {
  for (final int exitCode in [0, 1]) {
    test('only displays the pub.dev link after successful publication (exit $exitCode)', () async {
      final output = RecordingStdout();
      final result = await IOOverrides.runZoned(
        () => const PubPublishProcess().run(_PublishCmd(exitCode: exitCode), [
          PubspecContent.fromYaml({'name': 'my_app', 'version': '1.2.3'}, ''),
        ]),
        stdout: () => output,
      );

      if (exitCode == 0) {
        expect(result, isA<ReleaseProcessResultSuccess<PubPublished>>());
        expect(output.output.toString(), contains('Done.\nPackage : https://pub.dev/packages/my_app.\n'));
      } else {
        expect(result, isA<ReleaseProcessResultError>());
        expect(output.output.toString(), isNot(contains('https://pub.dev/')));
      }
    });
  }

  test('uses the configured package host in the published link', () async {
    final output = RecordingStdout();
    await IOOverrides.runZoned(
      () => const PubPublishProcess().run(const _PublishCmd(), [
        PubspecContent.fromYaml({'name': 'my_app', 'version': '1.2.3', 'publish_to': 'https://packages.example.com'}, ''),
      ]),
      stdout: () => output,
    );

    expect(output.output.toString(), contains('Package : https://packages.example.com/packages/my_app.\n'));
    expect(output.output.toString(), isNot(contains('https://pub.dev/')));
  });

  test('skips publication for private packages', () async {
    final result = await const PubPublishProcess().run(const _PublishCmd(), [
      PubspecContent.fromYaml({'name': 'my_app', 'version': '1.2.3', 'publish_to': 'none'}, ''),
    ]);

    expect(result, isA<ReleaseProcessResultCancelled>());
  });
}

class _PublishCmd extends Cmd {
  final int exitCode;

  const _PublishCmd({this.exitCode = 0}) : super(verbose: false);

  @override
  bool askQuestion(String question) => true;

  @override
  Future<ProcessResult> run({required String executable, List<String> arguments = const []}) async {
    expect(executable, 'dart');
    expect(arguments, ['pub', 'publish', '-f']);
    return ProcessResult(0, exitCode, '', '');
  }
}
