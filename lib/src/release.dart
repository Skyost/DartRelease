import 'package:release/src/processes/processes.dart';
import 'package:release/src/utils/cmd.dart';

/// The `release` utility main class.
class Release {
  /// The default processes to run.
  static const List<ReleaseProcess> defaultProcesses = [
    ReadPubspecProcess(),
    FindChangesProcess(),
    NewVersionProcess(),
    AskIgnoredScopesAndTypesProcess(),
    WriteChangelogProcess(),
    UpdatePubspecProcess(),
    UpdateSnapcraftProcess(),
    CommitAndPushProcess(),
    CreateGithubReleaseProcess(),
    CreateTagProcess(),
    PubPublishProcess(),
  ];

  /// Whether to print verbose output.
  final bool verbose;

  /// The processes to run.
  final List<ReleaseProcess> processes;

  /// Called when a process result is received.
  final Function(ReleaseProcess, ReleaseProcessResult)? onResult;

  /// Creates a new [Release] instance.
  const Release({
    this.verbose = false,
    this.processes = defaultProcesses,
    this.onResult,
  });

  /// Runs the release process.
  Future<void> release() async {
    Cmd cmd = Cmd(verbose: verbose);
    List<Object> results = [];
    for (ReleaseProcess process in processes) {
      ReleaseProcessResult result = await process.run(cmd, results);
      onResult?.call(process, result);
      if (result is ReleaseProcessResultSuccess) {
        results.add(result.value);
      }
    }
  }
}
