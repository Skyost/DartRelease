import 'package:pub_semver/pub_semver.dart';

/// Contains some useful methods to work with [Version].
extension VersionUtils on Version {
  /// Builds the version name, to use in changelogs.
  String buildName({bool includeBuild = false, bool includePreRelease = false}) {
    StringBuffer output = StringBuffer('$major.$minor.$patch');
    if (includePreRelease && preRelease.isNotEmpty) {
      output.write("-${preRelease.join('.')}");
    }
    String build = this.build.join();
    if (includeBuild && build.trim().isNotEmpty) {
      output.write('+$build');
    }
    return output.toString();
  }
}
