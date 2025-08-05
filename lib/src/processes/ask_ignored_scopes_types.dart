import 'dart:io';

import 'package:release/src/processes/processes.dart';
import 'package:release/src/utils/cmd.dart';

/// A process that asks the user to enter a comma separated list of scopes and types to ignore.
class AskIgnoredScopesAndTypesProcess with ReleaseProcess {
  /// Creates a new [AskIgnoredScopesAndTypesProcess] instance.
  const AskIgnoredScopesAndTypesProcess();

  @override
  ReleaseProcessResult run(Cmd cmd, List<Object> previousValues) {
    PubspecContent? pubspecContent = findValue<PubspecContent>(previousValues);
    if (pubspecContent == null) {
      return const ReleaseProcessResultCancelled();
    }

    List<String> scopes = pubspecContent.config.changelogDefaultIgnoredScopes;
    stdout.write('Enter a comma separated list of scopes to ignore (default is "${scopes.join(', ')}") or "Y" to continue. ');
    String input = cmd.readLine()?.toUpperCase() ?? 'Y';
    if (input != 'Y') {
      scopes = [
        for (String scope in input.split(',')) scope.trim(),
      ];
    }

    List<String> types = pubspecContent.config.changelogDefaultIgnoredTypes;
    stdout.write('Enter a comma separated list of types to ignore (default is "${types.join(', ')}") or "Y" to continue. ');
    input = cmd.readLine()?.toUpperCase() ?? 'Y';
    if (input != 'Y') {
      types = [
        for (String type in input.split(',')) type.trim(),
      ];
    }

    return ReleaseProcessResultSuccess(
      value: IgnoredScopesAndTypes(
        scopes: scopes,
        types: types,
      ),
    );
  }
}

/// The result of the [AskIgnoredScopesAndTypesProcess].
class IgnoredScopesAndTypes {
  /// The scopes to ignore.
  final List<String> scopes;

  /// The types to ignore.
  final List<String> types;

  /// Creates a new [IgnoredScopesAndTypes] instance.
  const IgnoredScopesAndTypes({
    required this.scopes,
    required this.types,
  });
}
