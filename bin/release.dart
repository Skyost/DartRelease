import 'dart:io';

import 'package:args/args.dart';
import 'package:release/release.dart';

/// This utility :
/// - Gets what has been commited this the latest version.
/// - Generates a changelog.
/// - Bumps the version.
/// - Makes a git tag.
/// - Commit and push the changes.
/// - Create a Github release.
Future<void> main(List<String> args) async {
  ArgParser parser = ArgParser();
  parser.addFlag(
    'verbose',
    abbr: 'v',
    help: 'Shows more detailed logs.',
  );
  parser.addFlag(
    'help',
    abbr: 'h',
    help: 'Prints this help message.',
    negatable: false,
  );
  ArgResults results = parser.parse(args);
  if (results.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }
  Release release = Release(
    verbose: results.flag('verbose'),
    onResult: (process, result) {
      if (result is ReleaseProcessResultError) {
        stderr.writeln('An error occurred during the execution of the process ${process.runtimeType}.');
        stderr.writeln(result.error);
        stderr.writeln(result.stackTrace);
      }
    },
  );
  await release.release();
}
