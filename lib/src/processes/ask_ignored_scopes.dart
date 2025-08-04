import 'dart:io';

import 'package:release/src/processes/process.dart';
import 'package:release/src/utils/cmd.dart';

/// A process that asks the user to enter a comma separated list of scopes to ignore.
class AskIgnoredScopesProcess with ReleaseProcess {
  /// Creates a new [AskIgnoredScopesProcess] instance.
  const AskIgnoredScopesProcess();

  @override
  ReleaseProcessResult run(Cmd cmd, List<Object> previousValues) {
    String defaultIgnoredScopes = 'docs,version,deps';
    stdout.write('Enter a comma separated list of scopes to ignore (default is "$defaultIgnoredScopes") or "Y" to continue. ');
    String input = cmd.readLine()?.toUpperCase() ?? 'Y';
    if (input == 'Y') {
      input = defaultIgnoredScopes;
    }
    return ReleaseProcessResultSuccess(
      value: IgnoredScopes(
        scopes: [
          for (String scope in input.split(',')) scope.trim(),
        ],
      ),
    );
  }
}

/// The result of the [AskIgnoredScopesProcess].
class IgnoredScopes {
  /// The scopes to ignore.
  final List<String> scopes;

  /// Creates a new [IgnoredScopes] instance.
  const IgnoredScopes({
    required this.scopes,
  });
}
