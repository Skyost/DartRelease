import 'dart:io';

import 'package:release/src/processes/processes.dart';
import 'package:release/src/utils/cmd.dart';

/// A process that asks the user to enter a comma separated list of scopes, types and hashes to ignore.
class AskIgnoredScopesTypesHashesProcess with ReleaseProcess, PubspecDependantReleaseProcess {
  /// Creates a new [AskIgnoredScopesTypesHashesProcess] instance.
  const AskIgnoredScopesTypesHashesProcess();

  @override
  String get id => 'ask-ignored-scopes-types-hashes';

  @override
  ReleaseProcessResult runWithPubspec(Cmd cmd, List<ReleaseProcessResultValue> previousValues, PubspecContent pubspecContent) {
    _AskIgnoredScopesAndTypesProcessConfig config = _readConfig(pubspecContent);
    List<String> scopes = config.defaultIgnoredScopes;
    stdout.write('Enter a comma separated list of scopes to ignore (default is "${scopes.join(', ')}") or "Y" to continue. ');
    String input = cmd.readLine()?.toUpperCase() ?? 'Y';
    if (input != 'Y') {
      scopes = [
        for (String scope in input.split(',')) scope.trim(),
      ];
    }

    List<String> types = config.defaultIgnoredTypes;
    stdout.write('Enter a comma separated list of types to ignore (default is "${types.join(', ')}") or "Y" to continue. ');
    input = cmd.readLine()?.toUpperCase() ?? 'Y';
    if (input != 'Y') {
      types = [
        for (String type in input.split(',')) type.trim(),
      ];
    }

    List<String> hashes = [];
    bool hideCommits = cmd.askQuestion('Do you want to ignore some other specific commits ?');
    if (hideCommits) {
      ChangeLogEntry? changeLogEntry = findValue<ChangeLogEntry>(previousValues);
      if (changeLogEntry != null) {
        stdout.writeln('Here are the commits :');
        stdout.writeAll([
          for (ConventionalCommitWithHash commit in changeLogEntry.subEntries.values.expand((commits) => commits))
            '#${commit.hash} ${commit.isBreakingChange ? 'BREAKING ' : ''}${commit.type?.toUpperCase() ?? ''} ${commit.description}\n',
        ]);
      }
      stdout.writeln('Please enter a comma separated list of hashes to hide.');
      String? input = cmd.readLine();
      if (input != null) {
        hashes = input.split(',').map((hash) {
          String trimmed = hash.trim();
          if (trimmed.startsWith('#')) {
            return trimmed.substring(1);
          }
          return trimmed;
        }).toList();
      }
    }

    return ReleaseProcessResultSuccess(
      value: IgnoredScopesTypesHashes(
        scopes: scopes,
        types: types,
        hashes: hashes,
      ),
    );
  }

  /// Reads the process configuration from the pubspec.yaml file.
  _AskIgnoredScopesAndTypesProcessConfig _readConfig(PubspecContent pubspecContent) => _AskIgnoredScopesAndTypesProcessConfig.fromYaml(readConfig(pubspecContent));
}

/// Holds the process configuration fields.
class _AskIgnoredScopesAndTypesProcessConfig {
  /// The default ignored scopes.
  /// These scopes will be ignored when generating the changelog.
  ///
  /// Read from the `defaultIgnoredScopes` field in the `changelog` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `['docs', 'version', 'deps']`.
  final List<String> defaultIgnoredScopes;

  /// The default ignored types.
  /// These types will be ignored when generating the changelog.
  ///
  /// Read from the `defaultIgnoredTypes` field in the `changelog` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `['test']`.
  final List<String> defaultIgnoredTypes;

  /// Creates a new [_AskIgnoredScopesAndTypesProcessConfig] instance.
  const _AskIgnoredScopesAndTypesProcessConfig({
    required this.defaultIgnoredScopes,
    required this.defaultIgnoredTypes,
  });

  /// Creates a [_AskIgnoredScopesAndTypesProcessConfig] from a YAML config.
  factory _AskIgnoredScopesAndTypesProcessConfig.fromYaml(Map releaseConfig) {
    Map changelog = releaseConfig['changelog'] ?? {};
    return _AskIgnoredScopesAndTypesProcessConfig(
      defaultIgnoredScopes: changelog['defaultIgnoredScopes']?.cast<String>() ?? ['docs', 'version', 'deps'],
      defaultIgnoredTypes: changelog['defaultIgnoredTypes']?.cast<String>() ?? ['test'],
    );
  }
}

/// The result of the [AskIgnoredScopesTypesHashesProcess].
class IgnoredScopesTypesHashes with ReleaseProcessResultValue {
  /// The scopes to ignore.
  final List<String> scopes;

  /// The types to ignore.
  final List<String> types;

  /// The hashes to ignore.
  final List<String> hashes;

  /// Creates a new [IgnoredScopesTypesHashes] instance.
  const IgnoredScopesTypesHashes({
    required this.scopes,
    required this.types,
    required this.hashes,
  });
}
