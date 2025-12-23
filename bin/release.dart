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
  parser.addOption(
    'processes',
    abbr: 'p',
    help: 'Comma separated list of processes to run. If not specified, all processes will be run.'
  );
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
  List<ReleaseProcess> processes = ReleaseProcess.allProcesses;
  List<ReleaseProcess>? wantedProcesses = results.option('processes')?.split(',').map(ReleaseProcess.fromId).whereType<ReleaseProcess>().toList();
  if (wantedProcesses != null && wantedProcesses.isNotEmpty) {
    processes = wantedProcesses;
  }
  
  Release release = Release(
    verbose: results.flag('verbose'),
    processes: processes,
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
