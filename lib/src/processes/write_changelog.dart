import 'dart:io';

import 'package:liquify/liquify.dart';
import 'package:release/src/processes/ask_ignored_scopes_types.dart';
import 'package:release/src/processes/find_changes.dart';
import 'package:release/src/processes/new_version.dart';
import 'package:release/src/processes/process.dart';
import 'package:release/src/processes/read_pubspec.dart';
import 'package:release/src/utils/cmd.dart';
import 'package:release/src/utils/version.dart';

/// A process that writes the `CHANGELOG.md` file.
class WriteChangelogProcess with ReleaseProcess {
  /// Creates a new [WriteChangelogProcess] instance.
  const WriteChangelogProcess();

  @override
  ReleaseProcessResult run(Cmd cmd, List<Object> previousValues) {
    ChangeLogEntry? changeLogEntry = findValue<ChangeLogEntry>(previousValues);
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    IgnoredScopesAndTypes? ignoredScopes = findValue<IgnoredScopesAndTypes>(previousValues);
    NewVersion? newVersion = findValue<NewVersion>(previousValues);
    if (changeLogEntry == null || pubspecContent == null || ignoredScopes == null || newVersion == null) {
      return const ReleaseProcessResultCancelled();
    }

    Map<String, dynamic> data = {
      'version': newVersion.version.buildName(includeBuild: false),
      'build': newVersion.version.build,
      'date': DateTime.now(),
      'repo': pubspecContent.config.githubRepository,
    };

    String markdownEntryTitle = Template.parse(pubspecContent.config.markdownEntryTitleTemplate, data: data).render();
    String markdownEntryHeader =
        '''$markdownEntryTitle
${Template.parse(pubspecContent.config.markdownEntryHeaderTemplate, data: data).render()}
''';
    String markdownEntryContent = _generateMarkdownContent(
      changeLogEntry: changeLogEntry,
      pubspecContent: pubspecContent,
      ignoredScopes: ignoredScopes,
      data: data,
    );
    File changeLogFile = File('./CHANGELOG.md');
    String changeLogHeader = Template.parse(pubspecContent.config.changelogHeader, data: data).render();
    String changeLogContent =
        '''$changeLogHeader

$markdownEntryHeader
$markdownEntryContent''';
    if (changeLogFile.existsSync()) {
      String fileContent = changeLogFile.readAsStringSync();
      changeLogContent = '''$changeLogContent
${fileContent.substring(changeLogHeader.length + 2)}''';
    }
    if (!changeLogContent.startsWith(changeLogHeader)) {
      return ReleaseProcessResultError(error: 'Current changelog does not start with the expected header. If you have changed in the configuration, please reflect the changes in the changelog file.');
    }
    stdout.writeln('Writing changelog content...');
    changeLogFile.writeAsStringSync(changeLogContent);
    stdout.writeln('Done.');
    return ReleaseProcessResultSuccess(
      value: MarkdownEntryContent(
        content: markdownEntryContent,
      ),
    );
  }

  /// Generates the Markdown content corresponding to this entry.
  String _generateMarkdownContent({
    required ChangeLogEntry changeLogEntry,
    required PubspecContent pubspecContent,
    required IgnoredScopesAndTypes ignoredScopes,
    required Map<String, dynamic> data,
  }) {
    String result = '';
    for (String type in changeLogEntry.subEntries.keys) {
      if (ignoredScopes.types.contains(type)) {
        continue;
      }
      for (ConventionalCommitWithHash entry in changeLogEntry.subEntries[type]!) {
        if (entry.scopes.firstWhere(ignoredScopes.scopes.contains, orElse: () => '').isNotEmpty) {
          continue;
        }
        result += Template.parse(
          pubspecContent.config.markdownEntryListItemTemplate,
          data: {
            ...data,
            'breaking': entry.isBreakingChange,
            'type': type,
            'description': entry.description,
            'hash': entry.hash,
          },
        ).render();
        result += '\n';
      }
    }
    return result;
  }
}

/// The result of the [WriteChangelogProcess].
class MarkdownEntryContent {
  /// The content of the entry.
  final String content;

  /// Creates a new [MarkdownEntryContent] instance.
  const MarkdownEntryContent({
    required this.content,
  });
}
