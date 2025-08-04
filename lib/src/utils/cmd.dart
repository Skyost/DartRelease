import 'dart:convert';
import 'dart:io';

/// A simple command line utility.
class Cmd {
  /// Whether to print verbose output.
  final bool verbose;

  /// Creates a new command line utility instance.
  const Cmd({
    required this.verbose,
  });

  /// Runs a command.
  Future<ProcessResult> run({
    required String executable,
    List<String> arguments = const [],
  }) async {
    if (verbose) {
      stdout.writeln('> "$executable ${arguments.join(' ')}"...');
    }
    ProcessResult result = await Process.run(
      executable,
      arguments,
      stderrEncoding: utf8,
      stdoutEncoding: utf8,
    );
    if (verbose) {
      stdout.writeln(result.stdout);
      if (result.exitCode != 0) {
        stderr.writeln('Non zero exit code returned (${result.exitCode}).');
        stderr.writeln(result.stderr);
      }
    }
    return result;
  }

  /// Reads a line from [stdin].
  String? readLine() => stdin.readLineSync(encoding: utf8)?.trim();

  /// Asks a Y/N question.
  bool askQuestion(String question) {
    stdout.write('$question (Y/N) ');
    String input = readLine()?.toUpperCase() ?? 'Y';
    while (input != 'Y' && input != 'YES' && input != 'N' && input != 'NO') {
      stderr.writeln('I have some trouble understanding your answer.');
      stdout.write('$question (Y/N) ');
      input = readLine()?.toUpperCase() ?? 'Y';
    }
    return input == 'Y' || input == 'YES';
  }
}
