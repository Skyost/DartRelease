import 'dart:io';

import 'package:release/src/processes/new_version.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/processes/read_pubspec.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/version.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// A process that updates the pubspec.yaml file.
class UpdateSnapcraftProcess with ReleaseProcess {
  /// Creates a new [UpdatePubspecProcess] instance.
  const UpdateSnapcraftProcess();

  @override
  ReleaseProcessResult run(Cmd cmd, List<Object> previousValues) {
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    NewVersion? newVersion = findValue<NewVersion>(previousValues);
    if (pubspecContent == null || newVersion == null) {
      return const ReleaseProcessResultCancelled();
    }
    File snapcraftFile = File('./snap/snapcraft.yaml');
    if (!snapcraftFile.existsSync()) {
      return const ReleaseProcessResultCancelled();
    }

    stdout.writeln('Writing version to "snap/snapcraft.yaml"...');
    YamlEditor editor = YamlEditor(snapcraftFile.readAsStringSync());
    editor.update(['version'], newVersion.version.buildName());
    String newContent = editor.toString();
    snapcraftFile.writeAsStringSync(newContent);
    stdout.writeln('Done.');

    return ReleaseProcessResultSuccess(
      value: SnapcraftUpdated(
        newContent: newContent,
      ),
    );
  }
}

/// The result of the [UpdateSnapcraftProcess].
class SnapcraftUpdated {
  /// The new content of the snapcraft.yaml file.
  final String newContent;

  /// Creates a new [SnapcraftUpdated] instance.
  const SnapcraftUpdated({
    required this.newContent,
  });
}
