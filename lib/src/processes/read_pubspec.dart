import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/src/config.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:yaml/yaml.dart' as yaml;

/// A process that reads the pubspec.yaml file.
class ReadPubspecProcess with ReleaseProcess {
  /// Creates a new [ReadPubspecProcess] instance.
  const ReadPubspecProcess();

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

  /// The read configuration.
  final ReleaseConfig config;

  /// The raw content of the pubspec.yaml file.
  final String content;

  /// Creates a new [PubspecContent] instance.
  const PubspecContent({
    required this.version,
    this.publishTo,
    required this.config,
    required this.content,
  });

  /// Creates a new [PubspecContent] instance from a YAML map.
  PubspecContent.fromYaml(Map pubspec, String content)
    : this(
        version: Version.parse(pubspec['version']),
        publishTo: pubspec['publish_to'],
        config: ReleaseConfig.fromYaml(pubspec),
        content: content,
      );
}
