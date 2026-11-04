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

  /// Writes a progress or informational message in cyan.
  void info(Object? message) => stdout.writeln(_colorize(message, 36, stdout));

  /// Writes a success message in green.
  void success(Object? message) => stdout.writeln(_colorize(message, 32, stdout));

  /// Writes a warning in yellow.
  void warning(Object? message) => stdout.writeln(_colorize(message, 33, stdout));

  /// Writes an error to stderr in red.
  void error(Object? message) => stderr.writeln(_colorize(message, 31, stderr));

  /// Writes a bold prompt without a trailing newline.
  void prompt(String message) => stdout.write(_colorize(message, 1, stdout));

  /// Uses ANSI styling only on supported terminals, respecting `NO_COLOR`.
  String _colorize(Object? message, int code, Stdout output) {
    if (Platform.environment.containsKey('NO_COLOR') || Platform.environment['TERM'] == 'dumb' || !output.hasTerminal || !output.supportsAnsiEscapes) {
      return '$message';
    }
    return '\x1B[${code}m$message\x1B[0m';
  }

  /// Runs a command.
  Future<ProcessResult> run({
    required String executable,
    List<String> arguments = const [],
  }) async {
    if (verbose) {
      info('> "$executable ${arguments.join(' ')}"...');
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
        error('Non zero exit code returned (${result.exitCode}).');
        stderr.writeln(result.stderr);
      }
    }
    return result;
  }

  /// Reads a line from [stdin].
  String? readLine() => stdin.readLineSync(encoding: utf8)?.trim();

  /// Asks a Y/N question.
  bool askQuestion(String question) {
    prompt('$question (Y/N) ');
    String input = readLine()?.toUpperCase() ?? 'Y';
    while (input != 'Y' && input != 'YES' && input != 'N' && input != 'NO') {
      error('I have some trouble understanding your answer.');
      prompt('$question (Y/N) ');
      input = readLine()?.toUpperCase() ?? 'Y';
    }
    return input == 'Y' || input == 'YES';
  }
}
