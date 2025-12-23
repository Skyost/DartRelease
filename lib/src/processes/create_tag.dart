import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/src/processes/commit_push.dart';
import 'package:release/src/processes/new_version.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/git.dart';

/// A process that asks the user to create a tag.
class CreateTagProcess with ReleaseProcess {
  /// Creates a new [CreateTagProcess] instance.
  const CreateTagProcess();

  @override
  String get id => 'create-tag';

  @override
  Future<ReleaseProcessResult> run(Cmd cmd, List<Object> previousValues) async {
    NewVersion? newVersion = findValue<NewVersion>(previousValues);
    CommitPushResult? commitPushResult = findValue<CommitPushResult>(previousValues);
    if (newVersion == null || commitPushResult?.pushed != false) {
      return const ReleaseProcessResultCancelled();
    }
    bool createTag = cmd.askQuestion('Do you want to create a tag ?');
    if (!createTag) {
      return const ReleaseProcessResultCancelled();
    }
    stdout.writeln('Creating a tag...');
    Git git = Git(cmd: cmd);
    bool tagResult = await git.tag(newVersion.version);
    if (!tagResult) {
      return ReleaseProcessResultError(error: 'Tag creation failed.');
    }
    stdout.writeln('Done.');
    return ReleaseProcessResultSuccess(
      value: TagCreated(
        version: newVersion.version,
      ),
    );
  }
}

/// The result of the [CreateTagProcess].
class TagCreated {
  /// The version of the tag.
  final Version version;

  /// Creates a new [TagCreated] instance.
  const TagCreated({
    required this.version,
  });
}
