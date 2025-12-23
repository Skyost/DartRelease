import 'dart:async';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:yaml/yaml.dart' as yaml;

/// A process that reads the pubspec.yaml file.
class ReadPubspecProcess with ReleaseProcess {
  /// Creates a new [ReadPubspecProcess] instance.
  const ReadPubspecProcess();

  @override
  String get id => 'read-pubspec';

  @override
  ReleaseProcessResult run(Cmd cmd, List<Object> previousValues) {
    File pubspecFile = File('./pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return ReleaseProcessResultError(error: 'Cannot find pubspec.yaml at "${pubspecFile.path}".');
    }
    String pubspecContentString = pubspecFile.readAsStringSync();
    Map pubspec = yaml.loadYaml(pubspecContentString) as Map;
    if (!pubspec.containsKey('version')) {
      return ReleaseProcessResultError(error: 'Cannot find current version.');
    }
    PubspecContent pubspecContent = PubspecContent.fromYaml(pubspec, pubspecContentString);
    stdout.writeln('Successfully read pubspec.yaml.');
    stdout.writeln('Current version is "${pubspecContent.version}".');
    return ReleaseProcessResultSuccess(value: pubspecContent);
  }
}

/// The result of the [ReadPubspecProcess].
class PubspecContent {
  /// The current version.
  final Version version;

  /// The `publish_to` field.
  final String? publishTo;

  /// The raw content of the pubspec.yaml file.
  final String rawContent;

  /// The content of the pubspec.yaml file.
  final Map _content;

  /// Creates a new [PubspecContent] instance.
  const PubspecContent({
    required this.version,
    this.publishTo,
    required this.rawContent,
    required Map content,
  }) : _content = content;

  /// Creates a new [PubspecContent] instance from a YAML map.
  PubspecContent.fromYaml(Map pubspec, String content)
    : this(
        version: Version.parse(pubspec['version']),
        publishTo: pubspec['publish_to'],
        content: pubspec,
        rawContent: content,
      );
}

/// A process that can be configured through the pubspec.yaml file.
mixin PubspecDependantReleaseProcess on ReleaseProcess {
  @override
  FutureOr<ReleaseProcessResult> run(Cmd cmd, List<Object> previousValues) {
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    if (pubspecContent == null) {
      return const ReleaseProcessResultCancelled();
    }
    return runWithPubspec(cmd, previousValues, pubspecContent);
  }

  /// Runs the process with the [pubspecContent].
  FutureOr<ReleaseProcessResult> runWithPubspec(Cmd cmd, List<Object> previousValues, PubspecContent pubspecContent);

  /// Reads the configuration from the pubspec.yaml file.
  Map readConfig(PubspecContent pubspecContent) => pubspecContent._content['release'] ?? {};

  /// The Github repository.
  /// Syntax is `username/repository`. May be `null`.
  ///
  /// Read from the `repository` field in the pubspec.yaml file,
  /// or from the `github` field in the `git` section of the `release`
  /// section of the pubspec.yaml file.
  String? readGithubRepository(PubspecContent pubspecContent) {
    Map git = readConfig(pubspecContent)['git'] ?? {};
    Uri? repositoryUrl = Uri.tryParse(git['github'] ?? pubspecContent._content['repository'] ?? '');
    if (repositoryUrl?.host != null && repositoryUrl?.host != 'github.com') {
      throw Exception('Only Github repositories are supported for the moment.');
    }

    String? githubRepository = repositoryUrl?.path;
    if (githubRepository != null) {
      if (githubRepository.startsWith('/')) {
        githubRepository = githubRepository.substring(1);
      }
      if (githubRepository.endsWith('/')) {
        githubRepository = githubRepository.substring(0, githubRepository.length - 1);
      }
    }
    return githubRepository;
  }
}
