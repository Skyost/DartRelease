/// This utility :
/// - Gets what has been commited this the latest version.
/// - Generates a changelog.
/// - Bumps the version.
/// - Makes a git tag.
/// - Commit and push the changes.
/// - Create a Github release.
library;

export 'src/processes/processes.dart';
export 'src/release.dart';
export 'src/utils/cmd.dart';
