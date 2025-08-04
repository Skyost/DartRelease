import 'dart:async';
import 'dart:io';

import 'package:release/src/processes/process.dart';
import 'package:release/src/processes/read_pubspec.dart';
import 'package:release/src/utils/cmd.dart';

/// A process that asks the user to publish to pub.dev.
class PubPublishProcess with ReleaseProcess {
  /// Creates a new [PubPublishProcess] instance.
  const PubPublishProcess();

  @override
  Future<ReleaseProcessResult> run(Cmd cmd, List<Object> previousValues) async {
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    if (pubspecContent == null || pubspecContent.publishTo == 'none') {
      return const ReleaseProcessResultCancelled();
    }

    bool publish = cmd.askQuestion('Do you want to publish the new version on pub.dev ?');
    if (!publish) {
      return const ReleaseProcessResultCancelled();
    }

    stdout.writeln('Publishing...');
    await cmd.run(
      executable: 'dart',
      arguments: ['pub', 'publish', '-f'],
    );
    stdout.writeln('Done.');
    return ReleaseProcessResultSuccess(
      value: PubPublished(),
    );
  }
}

class PubPublished {}
