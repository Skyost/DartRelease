import 'dart:io';

import 'package:release/src/processes/new_version.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/processes/read_pubspec.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// A process that updates the pubspec.yaml file.
class UpdatePubspecProcess with ReleaseProcess {
  /// Creates a new [UpdatePubspecProcess] instance.
  const UpdatePubspecProcess();

  @override
  ReleaseProcessResult run(Cmd cmd, List<Object> previousValues) {
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    NewVersion? newVersion = findValue<NewVersion>(previousValues);
    if (pubspecContent == null || newVersion == null) {
      return const ReleaseProcessResultCancelled();
    }
    YamlEditor editor = YamlEditor(pubspecContent.content);
    editor.update(['version'], newVersion.toString());
    stdout.writeln('Writing version to "pubspec.yaml" and running `flutter pub get`...');

    File pubspecFile = File('./pubspec.yaml');
    String newContent = editor.toString();
    pubspecFile.writeAsStringSync(newContent);
    cmd.run(
      executable: 'dart',
      arguments: ['pub', 'get'],
    );
    stdout.writeln('Done.');
    return ReleaseProcessResultSuccess(
      value: PubspecUpdated(
        newContent: newContent,
      ),
    );
  }
}

/// The result of the [UpdatePubspecProcess].
class PubspecUpdated {
  /// The new content of the pubspec.yaml file.
  final String newContent;

  /// Creates a new [PubspecUpdated] instance.
  const PubspecUpdated({
    required this.newContent,
  });
}
