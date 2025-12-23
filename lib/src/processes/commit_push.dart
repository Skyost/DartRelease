import 'dart:io';

import 'package:release/src/processes/processes.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/git.dart';

/// A process that asks the user to commit and push the changes.
class CommitAndPushProcess with ReleaseProcess, PubspecDependantReleaseProcess {
  /// Creates a new [CommitAndPushProcess] instance.
  const CommitAndPushProcess();

  @override
  String get id => 'commit-and-push';

  @override
  Future<ReleaseProcessResult> runWithPubspec(Cmd cmd, List<Object> previousValues, PubspecContent pubspecContent) async {
    bool hasPubspecChanged = findValue<PubspecUpdated>(previousValues) != null;
    FlatpakUpdated? flatpakUpdated = findValue<FlatpakUpdated>(previousValues);
    SnapcraftUpdated? snapcraftUpdated = findValue<SnapcraftUpdated>(previousValues);
    bool hasChangelogChanged = findValue<MarkdownEntryContent>(previousValues) != null;
    if (!hasPubspecChanged && flatpakUpdated == null && snapcraftUpdated == null && !hasChangelogChanged) {
      return const ReleaseProcessResultCancelled();
    }

    bool commit = cmd.askQuestion('Do you want to commit the changes ?');
    if (!commit) {
      return const ReleaseProcessResultCancelled();
    }

    _CommitAndPushProcessConfig config = _readConfig(pubspecContent);
    stdout.writeln('Committing changes...');
    Git git = Git(cmd: cmd);
    bool commitResult = await git.commit(
      files: [
        if (hasPubspecChanged) ...[
          'pubspec.yaml',
          'pubspec.lock',
        ],
        if (flatpakUpdated != null) flatpakUpdated.flatpakPath,
        if (snapcraftUpdated != null) snapcraftUpdated.snapcraftPath,
        if (hasChangelogChanged) 'CHANGELOG.md',
      ],
      message: config.newVersionCommitMessage,
    );
    if (!commitResult) {
      return ReleaseProcessResultError(error: 'Commit failed.');
    }
    stdout.writeln('Done.');
    bool push = cmd.askQuestion('Do you want to push the changes ?');
    bool pushResult = false;
    if (push) {
      stdout.writeln('Pushing...');
      pushResult = await git.push(config.remoteBranch);
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

  /// Reads the process configuration from the pubspec.yaml file.
  _CommitAndPushProcessConfig _readConfig(PubspecContent pubspecContent) => _CommitAndPushProcessConfig.fromYaml(readConfig(pubspecContent));
}

/// Holds the process configuration fields.
class _CommitAndPushProcessConfig {
  /// The commit message for the new version.
  /// Should be a conventional commit message.
  ///
  /// Read from the `newVersionCommitMessage` field in the `git` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `chore(version): Updated version and changelog.`.
  final String newVersionCommitMessage;

  /// The name of the remote branch.
  ///
  /// Read from the `remote` field in the `git` section of the `release` section
  /// of the pubspec.yaml file.
  /// Defaults to `main`.
  final String remoteBranch;

  /// Creates a new [_CommitAndPushProcessConfig] instance.
  const _CommitAndPushProcessConfig({
    required this.newVersionCommitMessage,
    required this.remoteBranch,
  });

  /// Creates a [_CommitAndPushProcessConfig] from a YAML config.
  factory _CommitAndPushProcessConfig.fromYaml(Map releaseConfig) {
    Map git = releaseConfig['git'] ?? {};
    return _CommitAndPushProcessConfig(
      newVersionCommitMessage: git['newVersionCommitMessage'] ?? 'chore(version): Updated version and changelog.',
      remoteBranch: git['remote'] ?? 'main',
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
