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
class WriteChangelogProcess with ReleaseProcess, PubspecDependantReleaseProcess {
  /// Creates a new [WriteChangelogProcess] instance.
  const WriteChangelogProcess();

  @override
  String get id => 'write-changelog';

  @override
  ReleaseProcessResult runWithPubspec(Cmd cmd, List<Object> previousValues, PubspecContent pubspecContent) {
    ChangeLogEntry? changeLogEntry = findValue<ChangeLogEntry>(previousValues);
    IgnoredScopesAndTypes? ignoredScopes = findValue<IgnoredScopesAndTypes>(previousValues);
    NewVersion? newVersion = findValue<NewVersion>(previousValues);
    if (changeLogEntry == null || ignoredScopes == null || newVersion == null) {
      return const ReleaseProcessResultCancelled();
    }

    String? repository = readGithubRepository(pubspecContent);
    if (repository == null) {
      return ReleaseProcessResultError(error: 'Cannot find the Github repository in the pubspec.');
    }
    _WriteChangelogProcessConfig config = _readConfig(pubspecContent);
    String? githubRepository = readGithubRepository(pubspecContent);
    Map<String, dynamic> data = {
      'version': newVersion.version.buildName(includeBuild: false),
      'build': newVersion.version.build,
      'date': DateTime.now(),
      if (githubRepository != null) 'repo': githubRepository,
    };

    String markdownEntryTitle = Template.parse(config.markdownEntryTitleTemplate, data: data).render();
    String markdownEntryHeader =
        '''$markdownEntryTitle
${Template.parse(config.markdownEntryHeaderTemplate, data: data).render()}
''';
    String markdownEntryContent = _generateMarkdownContent(
      changeLogEntry: changeLogEntry,
      config: config,
      ignoredScopes: ignoredScopes,
      data: data,
    );
    File changeLogFile = File('./CHANGELOG.md');
    String changeLogHeader = Template.parse(config.changelogHeader, data: data).render();
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
    required _WriteChangelogProcessConfig config,
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
          config.markdownEntryListItemTemplate,
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

  /// Reads the process configuration from the pubspec.yaml file.
  _WriteChangelogProcessConfig _readConfig(PubspecContent pubspecContent) => _WriteChangelogProcessConfig.fromYaml(readConfig(pubspecContent));
}

/// Holds the process configuration fields.
class _WriteChangelogProcessConfig {
  /// The changelog header.
  /// Should be a Markdown heading 1 level title.
  ///
  /// Read from the `header` field in the `changelog` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `# 📰 Changelog`.
  final String changelogHeader;

  /// The template for the title of a changelog entry.
  /// Parsed with the following data :
  /// - `version`: The version of the changelog entry.
  /// - `build`: The build number of the changelog entry.
  /// - `date`: The date of the changelog entry.
  /// - `repo`: The Github repository, which is [githubRepository].
  ///
  /// Read from the `title` field in the `entry` section of the `changelog` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `## v{{ version }}`.
  final String markdownEntryTitleTemplate;

  /// The template for the header of a changelog entry.
  /// Parsed with the following data :
  /// - `version`: The version of the changelog entry.
  /// - `build`: The build number of the changelog entry.
  /// - `date`: The date of the changelog entry.
  /// - `repo`: The Github repository, which is [githubRepository].
  ///
  /// Read from the `header` field in the `entry` section of the `changelog` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `Released on {{ date | date: "MMMM d, yyyy" }}.`.
  final String markdownEntryHeaderTemplate;

  /// The template for a list item of a changelog entry.
  /// Parsed with the following data :
  /// - `version`: The version of the changelog entry.
  /// - `build`: The build number of the changelog entry.
  /// - `date`: The date of the changelog entry.
  /// - `repo`: The Github repository, which is [githubRepository].
  /// - `breaking`: Whether the changelog entry is a breaking change.
  /// - `type`: The type of the changelog entry.
  /// - `description`: The description of the changelog entry.
  /// - `hash`: The hash of the changelog entry.
  ///
  /// Read from the `item` field in the `entry` section of the `changelog` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `* **{% if breaking %}BREAKING {% endif %}{{ type | upcase }}**: {{ description }} ({% if repo %}[#{{ hash }}](https://github.com/{{ repo }}/commit/{{ hash }}){% else %}#{{ hash }}{% endif %})`.
  final String markdownEntryListItemTemplate;

  /// Creates a new [_WriteChangelogProcessConfig] instance.
  const _WriteChangelogProcessConfig({
    required this.changelogHeader,
    required this.markdownEntryTitleTemplate,
    required this.markdownEntryHeaderTemplate,
    required this.markdownEntryListItemTemplate,
  });

  /// Creates a [_WriteChangelogProcessConfig] from a YAML config.
  factory _WriteChangelogProcessConfig.fromYaml(Map releaseConfig) {
    Map changelog = releaseConfig['changelog'] ?? {};
    Map changelogEntry = changelog['entry'] ?? {};
    return _WriteChangelogProcessConfig(
      changelogHeader: changelog['header'] ?? '# 📰 Changelog',
      markdownEntryTitleTemplate: changelogEntry['title'] ?? '## v{{ version }}',
      markdownEntryHeaderTemplate: changelogEntry['header'] ?? 'Released on {{ date | date: "MMMM d, yyyy" }}.',
      markdownEntryListItemTemplate:
          changelogEntry['item'] ??
          '* **{% if breaking %}BREAKING {% endif %}{{ type | upcase }}**: {{ description }} ({% if repo %}[#{{ hash }}](https://github.com/{{ repo }}/commit/{{ hash }}){% else %}#{{ hash }}{% endif %})',
    );
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
