import 'dart:collection';
import 'dart:io';

import 'package:conventional_commit/conventional_commit.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/git.dart';

/// A process that finds changes since the last tag.
class FindChangesProcess with ReleaseProcess {
  /// Creates a new [FindChangesProcess] instance.
  const FindChangesProcess();

  @override
  Future<ReleaseProcessResult> run(Cmd cmd, List<Object> previousValues) async {
    Git git = Git(cmd: cmd);
    String? lastTag = await git.findLastTag();
    if (lastTag == null) {
      return ReleaseProcessResultError(error: 'Cannot find last tag.');
    }
    stdout.writeln('Last tag is "$lastTag".');
    ProcessResult result = await cmd.run(
      executable: 'git',
      arguments: ['log', '$lastTag..HEAD', '--oneline'],
    );
    ChangeLogEntry changeLogEntry = ChangeLogEntry.parseGitLog(result.stdout);
    if (changeLogEntry.isEmpty) {
      stdout.writeln('Found no change.');
    } else if (changeLogEntry.hasBreakingChange) {
      stdout.writeln('Found a breaking change.');
    } else {
      stdout.writeln('Found no breaking change.');
    }
    return ReleaseProcessResultSuccess(value: changeLogEntry);
  }
}

/// A simple changelog entry, containing sub-entries.
class ChangeLogEntry {
  /// The types, ordered.
  static const List<String> orderedTypes = [
    'feat',
    'fix',
    'chore',
    'refactor',
    'test',
    'ci',
  ];

  /// The sub-entries (ie. messages).
  final SplayTreeMap<String, List<ConventionalCommitWithHash>> subEntries;

  /// Whether this entry has a breaking change.
  bool hasBreakingChange;

  /// Creates a new changelog entry instance.
  ChangeLogEntry({
    SplayTreeMap<String, List<ConventionalCommitWithHash>>? subEntries,
    this.hasBreakingChange = false,
  }) : subEntries = subEntries ?? SplayTreeMap(_compareTypes);

  /// Parses a git log and returns a changelog entry.
  static ChangeLogEntry parseGitLog(String gitLog) {
    ChangeLogEntry result = ChangeLogEntry();
    List<String> lines = gitLog.split('\n');
    for (String line in lines) {
      ConventionalCommitWithHash? commit = ConventionalCommitWithHash.tryParse(line);
      if (commit?.type == null || commit?.description == null) {
        continue;
      }
      result.addSubEntry(commit!);
    }
    return result;
  }

  /// Whether this entry is empty.
  bool get isEmpty => subEntries.isEmpty;

  /// Adds a sub-entry to the list.
  void addSubEntry(ConventionalCommitWithHash commit) {
    List<ConventionalCommitWithHash>? commitsOfType = subEntries[commit.type!];
    if (commitsOfType == null) {
      subEntries[commit.type!] = [commit];
    } else {
      for (ConventionalCommitWithHash commitWithHash in commitsOfType) {
        if (commitWithHash.description == commit.description) {
          return;
        }
      }
      commitsOfType.add(commit);
      commitsOfType.sort(_compareConventionalCommits);
    }
    hasBreakingChange = hasBreakingChange || commit.isBreakingChange;
  }

  /// Allows to compare two commit types.
  static int _compareTypes(String a, String b) {
    int aIndex = orderedTypes.indexOf(a);
    int bIndex = orderedTypes.indexOf(b);
    if (aIndex == -1) {
      if (bIndex == -1) {
        return a.compareTo(b);
      }
      return -1;
    }
    return aIndex.compareTo(bIndex);
  }

  /// Compares two conventional commits based on their description.
  int _compareConventionalCommits(ConventionalCommitWithHash a, ConventionalCommitWithHash b) {
    if ((a.isBreakingChange && b.isBreakingChange) || (!a.isBreakingChange && !b.isBreakingChange)) {
      return a.description!.compareTo(b.description!);
    }
    return a.isBreakingChange ? -1 : 1;
  }

  /// Creates a new version, bumped from the current [version].
  Version bumpVersion(Version version) {
    int? buildNumber = int.tryParse(version.build.join());
    return Version(
      version.major,
      hasBreakingChange ? (version.minor + 1) : version.minor,
      hasBreakingChange ? 0 : (version.patch + 1),
      build: buildNumber == null ? null : (buildNumber + 1).toString(),
    );
  }
}

/// Just a wrapper for a [ConventionalCommit] holding a [hash].
class ConventionalCommitWithHash {
  /// The [ConventionalCommit] instance.
  final ConventionalCommit commit;

  /// The commit hash.
  final String hash;

  /// Creates a new conventional commit
  const ConventionalCommitWithHash({
    required this.commit,
    required this.hash,
  });

  /// Tries to parse a git log line.
  static ConventionalCommitWithHash? tryParse(String gitLogLine) {
    if (!gitLogLine.startsWith(RegExp('[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9] '))) {
      return null;
    }
    ConventionalCommit? commit = ConventionalCommit.tryParse(gitLogLine.substring(8));
    if (commit == null) {
      return null;
    }
    return ConventionalCommitWithHash(
      commit: commit,
      hash: gitLogLine.substring(0, 7),
    );
  }

  /// Maps to [commit.scopes].
  List<String> get scopes => commit.scopes;

  /// Maps to [commit.type].
  String? get type => commit.type;

  /// Maps to [commit.isFeature].
  bool get isFeature => commit.isFeature;

  /// Maps to [commit.isFix].
  bool get isFix => commit.isFix;

  /// Maps to [commit.isBreakingChange].
  bool get isBreakingChange => commit.isBreakingChange;

  /// Maps to [commit.breakingChangeDescription].
  String? get breakingChangeDescription => commit.breakingChangeDescription;

  /// Maps to [commit.isMergeCommit].
  bool get isMergeCommit => commit.isMergeCommit;

  /// Maps to [commit.description].
  String? get description => commit.description;

  /// Maps to [commit.header].
  String get header => commit.header;

  /// Maps to [commit.body].
  String? get body => commit.body;

  /// Maps to [commit.footers].
  List<String> get footers => commit.footers;
}
