/// The release utility configuration class.
class ReleaseConfig {
  /// The Github repository.
  /// Syntax is `username/repository`. May be `null`.
  ///
  /// Read from the `repository` field in the pubspec.yaml file,
  /// or from the `github` field in the `git` section of the `release`
  /// section of the pubspec.yaml file.
  final String? githubRepository;

  /// The default ignored scopes.
  /// These scopes will be ignored when generating the changelog.
  ///
  /// Read from the `defaultIgnoredScopes` field in the `changelog` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `['docs', 'version', 'deps']`.
  final List<String> changelogDefaultIgnoredScopes;


  /// The default ignored types.
  /// These types will be ignored when generating the changelog.
  ///
  /// Read from the `defaultIgnoredTypes` field in the `changelog` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `['test']`.
  final List<String> changelogDefaultIgnoredTypes;

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

  /// The commit message for the new version.
  /// Should be a conventional commit message.
  ///
  /// Read from the `newVersionCommitMessage` field in the `git` section
  /// of the `release` section of the pubspec.yaml file.
  /// Defaults to `chore(version): Updated version and changelog.`.
  final String newVersionCommitMessage;

  /// The name of the remote branch.
  ///
  /// Read from the `remote` field in the `git` section of the `release` section
  /// of the pubspec.yaml file.
  /// Defaults to `main`.
  final String remoteBranch;

  /// Creates a new [ReleaseConfig] instance.
  const ReleaseConfig({
    required this.githubRepository,
    required this.changelogHeader,
    required this.changelogDefaultIgnoredScopes,
    required this.changelogDefaultIgnoredTypes,
    required this.markdownEntryTitleTemplate,
    required this.markdownEntryHeaderTemplate,
    required this.markdownEntryListItemTemplate,
    required this.newVersionCommitMessage,
    required this.remoteBranch,
  });

  /// Creates a [ReleaseConfig] from a YAML config.
  factory ReleaseConfig.fromYaml(Map config) {
    Map releaseConfig = config['release'] ?? {};

    Map changelog = releaseConfig['changelog'] ?? {};
    Map changelogEntry = changelog['entry'] ?? {};

    Map git = releaseConfig['git'] ?? {};
    Uri? repositoryUrl = Uri.tryParse(git['github'] ?? config['repository'] ?? '');
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

    return ReleaseConfig(
      githubRepository: githubRepository,
      changelogHeader: changelog['header'] ?? '# 📰 Changelog',
      changelogDefaultIgnoredScopes: changelog['defaultIgnoredScopes']?.cast<String>() ?? ['docs', 'version', 'deps'],
      changelogDefaultIgnoredTypes: changelog['defaultIgnoredTypes']?.cast<String>() ?? ['test'],
      markdownEntryTitleTemplate: changelogEntry['title'] ?? '## v{{ version }}',
      markdownEntryHeaderTemplate: changelogEntry['header'] ?? 'Released on {{ date | date: "MMMM d, yyyy" }}.',
      markdownEntryListItemTemplate:
          changelogEntry['item'] ??
          '* **{% if breaking %}BREAKING {% endif %}{{ type | upcase }}**: {{ description }} ({% if repo %}[#{{ hash }}](https://github.com/{{ repo }}/commit/{{ hash }}){% else %}#{{ hash }}{% endif %})',
      newVersionCommitMessage: git['newVersionCommitMessage'] ?? 'chore(version): Updated version and changelog.',
      remoteBranch: git['remote'] ?? 'main',
    );
  }
}
