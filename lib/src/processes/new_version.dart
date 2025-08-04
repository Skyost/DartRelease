import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
import 'package:release/src/processes/find_changes.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/processes/read_pubspec.dart';
import 'package:release/src/utils/cmd.dart';

/// A process that asks the user for a new version.
class NewVersionProcess with ReleaseProcess {
  /// Creates a new [NewVersionProcess] instance.
  const NewVersionProcess();

  @override
  ReleaseProcessResult run(Cmd cmd, List<Object> previousValues) {
    ChangeLogEntry? changeLogEntry = findValue<ChangeLogEntry>(previousValues);
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    if (changeLogEntry == null || pubspecContent == null) {
      return const ReleaseProcessResultCancelled();
    }
    Version newVersion = changeLogEntry.bumpVersion(pubspecContent.version);
    stdout.write('Proposed new version is "$newVersion", enter "Y" to continue or type a new version proposal. Type "N" to cancel. ');
    String input = cmd.readLine()?.toUpperCase() ?? 'N';
    if (input == 'N') {
      return const ReleaseProcessResultCancelled();
    }
    if (input != 'Y') {
      newVersion = Version.parse(input);
    }
    return ReleaseProcessResultSuccess(
      value: NewVersion(
        version: newVersion,
      ),
    );
  }
}

/// The result of the [NewVersionProcess].
class NewVersion {
  /// The new version.
  final Version version;

  /// Creates a new [NewVersion] instance.
  const NewVersion({
    required this.version,
  });
}
