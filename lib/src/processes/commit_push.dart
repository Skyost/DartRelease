import 'dart:async';
import 'dart:io';

import 'package:release/src/processes/processes.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/git.dart';

/// A process that asks the user to commit and push the changes.
class CommitAndPushProcess with ReleaseProcess {
  /// Creates a new [CommitAndPushProcess] instance.
  const CommitAndPushProcess();

  @override
  Future<ReleaseProcessResult> run(Cmd cmd, List<Object> previousValues) async {
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    if (pubspecContent == null) {
      return const ReleaseProcessResultCancelled();
    }

    bool hasPubspecChanged = findValue<PubspecUpdated>(previousValues) != null;
    bool hasSnapcraftChanged = findValue<SnapcraftUpdated>(previousValues) != null;
    bool hasChangelogChanged = findValue<MarkdownEntryContent>(previousValues) != null;
    if (!hasPubspecChanged && !hasSnapcraftChanged && !hasChangelogChanged) {
      return const ReleaseProcessResultCancelled();
    }

    bool commit = cmd.askQuestion('Do you want to commit the changes ?');
    if (!commit) {
      return const ReleaseProcessResultCancelled();
    }
    stdout.writeln('Committing changes...');
    Git git = Git(cmd: cmd);
    bool commitResult = await git.commit(
      files: [
        if (hasPubspecChanged) ...[
          'pubspec.yaml',
          'pubspec.lock',
        ],
        if (hasSnapcraftChanged) 'snap/snapcraft.yaml',
        if (hasChangelogChanged) 'CHANGELOG.md',
      ],
      message: pubspecContent.config.newVersionCommitMessage,
    );
    if (!commitResult) {
      return ReleaseProcessResultError(error: 'Commit failed.');
    }
    stdout.writeln('Done.');
    bool push = cmd.askQuestion('Do you want to push the changes ?');
    bool pushResult = false;
    if (push) {
      stdout.writeln('Pushing...');
      pushResult = await git.push(pubspecContent.config.remoteBranch);
      if (!pushResult) {
        return ReleaseProcessResultError(error: 'Push failed.');
      }
      stdout.writeln('Done.');
    }
    return ReleaseProcessResultSuccess(
      value: CommitPushResult(
        committed: commitResult,
        pushed: pushResult,
      ),
    );
  }
}

/// The result of the [CommitAndPushProcess].
class CommitPushResult {
  /// Whether the changes were committed.
  final bool committed;

  /// Whether the changes were pushed.
  final bool pushed;

  /// Creates a new [CommitPushResult] instance.
  const CommitPushResult({
    required this.committed,
    required this.pushed,
  });
}
