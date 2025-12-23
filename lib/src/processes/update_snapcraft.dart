import 'dart:io';

import 'package:release/src/processes/new_version.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/processes/read_pubspec.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/version.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// A process that updates the snapcraft.yaml file.
class UpdateSnapcraftProcess with ReleaseProcess, PubspecDependantReleaseProcess {
  /// Creates a new [UpdateSnapcraftProcess] instance.
  const UpdateSnapcraftProcess();

  @override
  String get id => 'update-snapcraft';

  @override
  ReleaseProcessResult runWithPubspec(Cmd cmd, List<Object> previousValues, PubspecContent pubspecContent) {
    NewVersion? newVersion = findValue<NewVersion>(previousValues);
    if (newVersion == null) {
      return const ReleaseProcessResultCancelled();
    }
    _UpdateSnapcraftProcessConfig config = _readConfig(pubspecContent);
    File snapcraftFile = File(config.snapcraftPath);
    if (!snapcraftFile.existsSync()) {
      return const ReleaseProcessResultCancelled();
    }

    stdout.writeln('Writing version to "${config.snapcraftPath}"...');
    YamlEditor editor = YamlEditor(snapcraftFile.readAsStringSync());
    editor.update(['version'], newVersion.version.buildName());
    String newContent = editor.toString();
    snapcraftFile.writeAsStringSync(newContent);
    stdout.writeln('Done.');

    return ReleaseProcessResultSuccess(
      value: SnapcraftUpdated(
        snapcraftPath: config.snapcraftPath,
        newContent: newContent,
      ),
    );
  }

  /// Reads the process configuration from the pubspec.yaml file.
  _UpdateSnapcraftProcessConfig _readConfig(PubspecContent pubspecContent) => _UpdateSnapcraftProcessConfig.fromYaml(readConfig(pubspecContent));
}

/// Holds the process configuration fields.
class _UpdateSnapcraftProcessConfig {
  /// The path to the snapcraft.yaml file.
  ///
  /// Defaults to `./snap/snapcraft.yaml`.
  final String snapcraftPath;

  /// Creates a new [_UpdateSnapcraftProcessConfig] instance.
  const _UpdateSnapcraftProcessConfig({
    required this.snapcraftPath,
  });

  /// Creates a [_UpdateSnapcraftProcessConfig] from a YAML config.
  factory _UpdateSnapcraftProcessConfig.fromYaml(Map releaseConfig) => _UpdateSnapcraftProcessConfig(
    snapcraftPath: releaseConfig['snapcraftPath'] ?? './snap/snapcraft.yaml',
  );
}

/// The result of the [UpdateSnapcraftProcess].
class SnapcraftUpdated {
  /// The path to the snapcraft.yaml file.
  final String snapcraftPath;

  /// The new content of the snapcraft.yaml file.
  final String newContent;

  /// Creates a new [SnapcraftUpdated] instance.
  const SnapcraftUpdated({
    required this.snapcraftPath,
    required this.newContent,
  });
}
