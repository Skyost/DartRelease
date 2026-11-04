import 'dart:io';

/// Captures console output without writing to the terminal.
class RecordingStdout implements Stdout {
  final StringBuffer output = StringBuffer();

  @override
  bool get supportsAnsiEscapes => false;

  @override
  void write(Object? object) => output.write(object);

  @override
  void writeln([Object? object = '']) => output.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
