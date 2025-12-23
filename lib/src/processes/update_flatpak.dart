import 'dart:io';

import 'package:release/src/processes/ask_ignored_scopes_types.dart';
import 'package:release/src/processes/find_changes.dart';
import 'package:release/src/processes/new_version.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/processes/read_pubspec.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/version.dart';
import 'package:xml/xml.dart';

/// A process that updates the flatpak.yaml file.
class UpdateFlatpakProcess with ReleaseProcess, PubspecDependantReleaseProcess {
  /// Creates a new [UpdateFlatpakProcess] instance.
  const UpdateFlatpakProcess();

  @override
  String get id => 'update-flatpak';

  @override
  ReleaseProcessResult runWithPubspec(Cmd cmd, List<Object> previousValues, PubspecContent pubspecContent) {
    IgnoredScopesAndTypes? ignoredScopes = findValue<IgnoredScopesAndTypes>(previousValues);
    NewVersion? newVersion = findValue<NewVersion>(previousValues);
    if (ignoredScopes == null || newVersion == null) {
      return const ReleaseProcessResultCancelled();
    }
    _UpdateFlatpakProcessConfig config = _readConfig(pubspecContent);
    File flatpakFile = File(config.flatpakPath);
    if (!flatpakFile.existsSync()) {
      return const ReleaseProcessResultCancelled();
    }

    stdout.writeln('Updating "${config.flatpakPath}"...');

    ChangeLogEntry? changeLogEntry = findValue<ChangeLogEntry>(previousValues);
    String? githubRepository = readGithubRepository(pubspecContent);
    String formatDate(DateTime date) {
      String month = date.month.toString().padLeft(2, '0');
      String day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    }

    XmlElement? release = XmlElement(
      XmlName('release'),
      [
        XmlAttribute(XmlName('version'), newVersion.version.buildName()),
        XmlAttribute(XmlName('date'), formatDate(DateTime.now())),
      ],
      [
        if (githubRepository != null)
          XmlElement(
            XmlName('url'),
            [
              XmlAttribute(XmlName('type'), 'details'),
            ],
            [
              XmlText('https://github.com/$githubRepository/releases/tag/${newVersion.version.buildName()}'),
            ],
          ),
        if (changeLogEntry != null)
          XmlElement(
            XmlName('description'),
            [
              XmlAttribute(XmlName('type'), 'changelog'),
            ],
            [
              _generateDescription(
                ignoredScopes: ignoredScopes,
                changeLogEntry: changeLogEntry,
              ),
            ],
          ),
      ],
    );

    XmlDocument document = XmlDocument.parse(flatpakFile.readAsStringSync());
    XmlElement? releases = document.rootElement.findElements('releases').firstOrNull;
    if (releases == null) {
      releases = XmlElement(
        XmlName('releases'),
        [],
        [release],
      );
      document.rootElement.children.add(releases);
    } else {
      releases.children.insert(0, release);
    }

    String newContent = document.toXmlString(pretty: true);
    flatpakFile.writeAsStringSync(newContent);
    stdout.writeln('Done.');

    return ReleaseProcessResultSuccess(
      value: FlatpakUpdated(
        flatpakPath: config.flatpakPath,
        newContent: newContent,
      ),
    );
  }

  /// Reads the process configuration from the pubspec.yaml file.
  _UpdateFlatpakProcessConfig _readConfig(PubspecContent pubspecContent) => _UpdateFlatpakProcessConfig.fromYaml(readConfig(pubspecContent));

  /// Generates the description of a given changelog entry.
  XmlElement _generateDescription({
    required IgnoredScopesAndTypes ignoredScopes,
    required ChangeLogEntry changeLogEntry,
  }) {
    List<XmlElement> result = [];
    for (String type in changeLogEntry.subEntries.keys) {
      if (ignoredScopes.types.contains(type)) {
        continue;
      }
      for (ConventionalCommitWithHash entry in changeLogEntry.subEntries[type]!) {
        if (entry.scopes.firstWhere(ignoredScopes.scopes.contains, orElse: () => '').isNotEmpty) {
          continue;
        }
        if (entry.description != null) {
          result.add(
            XmlElement(
              XmlName('li'),
              [],
              [
                XmlText(entry.description!),
              ],
            ),
          );
        }
      }
    }
    return XmlElement(
      XmlName('ul'),
      [],
      result,
    );
  }
}

/// Holds the process configuration fields.
class _UpdateFlatpakProcessConfig {
  /// The path to the flatpak metadata file.
  ///
  /// Defaults to `./flatpak/app.metainfo.xml`.
  final String flatpakPath;

  /// Creates a new [_UpdateFlatpakProcessConfig] instance.
  const _UpdateFlatpakProcessConfig({
    required this.flatpakPath,
  });

  /// Creates a [_UpdateFlatpakProcessConfig] from a YAML config.
  factory _UpdateFlatpakProcessConfig.fromYaml(Map releaseConfig) => _UpdateFlatpakProcessConfig(
    flatpakPath: releaseConfig['flatpakPath'] ?? './flatpak/app.metainfo.xml',
  );
}

/// The result of the [UpdateFlatpakProcess].
class FlatpakUpdated {
  /// The path to the flatpak metadata file.
  final String flatpakPath;

  /// The new content of the flatpak.yaml file.
  final String newContent;

  /// Creates a new [FlatpakUpdated] instance.
  const FlatpakUpdated({
    required this.flatpakPath,
    required this.newContent,
  });
}
