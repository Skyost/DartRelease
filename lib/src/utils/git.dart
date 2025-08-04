import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/src/utils/cmd.dart';

/// A simple Git utility.
class Git {
  /// The command line utility.
  final Cmd cmd;

  /// Creates a new Git instance.
  const Git({
    required this.cmd,
  });

  /// Finds the last tag of the current git repository.
  Future<String?> findLastTag({bool autoCreate = true}) async {
    ProcessResult result = await cmd.run(
      executable: 'git',
      arguments: ['describe', '--tags', '--abbrev=0'],
    );
    switch (result.exitCode) {
      case 0:
        return result.stdout.replaceAll('\n', '');
      case 128:
        String? firstCommit = await findLastCommit(reverse: true);
        if (firstCommit == null || !autoCreate) {
          return null;
        }
        await cmd.run(
          executable: 'git',
          arguments: ['tag', '-a', '0.0.0', firstCommit, '-m', 'First commit.'],
        );
        return findLastTag(autoCreate: false);
    }
    return null;
  }

  /// Finds the last commit.
  Future<String?> findLastCommit({bool reverse = false}) async {
    ProcessResult result = await cmd.run(
      executable: 'git',
      arguments: ['log', '--oneline', if (reverse) '--reverse'],
    );
    List<String> lines = result.stdout.split('\n');
    String? lastCommit = lines.isEmpty ? null : lines.first.split(' ').first.trim();
    return lastCommit?.isEmpty == true ? null : lastCommit;
  }

  /// Commits the given files.
  Future<bool> commit({
    required List<String> files,
    String? message,
  }) async {
    List<String> filesToCommit = List.of(files);
    for (String file in files) {
      ProcessResult result = await cmd.run(
        executable: 'git',
        arguments: ['check-ignore', file],
      );
      if (result.exitCode == 0) {
        filesToCommit.remove(file);
      }
    }

    ProcessResult result = await cmd.run(
      executable: 'git',
      arguments: ['add', ...filesToCommit],
    );
    if (result.exitCode != 0) {
      return false;
    }
    result = await cmd.run(
      executable: 'git',
      arguments: [
        'commit',
        if (message != null) ...['-m', message],
      ],
    );
    return result.exitCode == 0;
  }

  /// Pushes the current branch.
  Future<bool> push(String branch) async {
    ProcessResult result = await cmd.run(
      executable: 'git',
      arguments: ['push', 'origin', branch],
    );
    return result.exitCode == 0;
  }

  /// Tags the given version.
  Future<bool> tag(Version version) async {
    ProcessResult result = await cmd.run(
      executable: 'git',
      arguments: ['tag', '-a', version.toString(), '-m', 'v$version'],
    );
    return result.exitCode == 0;
  }

  Future<bool> fetch(List<String> arguments) async {
    ProcessResult result = await cmd.run(
      executable: 'git',
      arguments: ['fetch', ...arguments],
    );
    return result.exitCode == 0;
  }
}
