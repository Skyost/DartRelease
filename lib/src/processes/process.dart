import 'dart:async';

import 'package:meta/meta.dart';
import 'package:release/src/release.dart';
import 'package:release/src/utils/cmd.dart';

/// A process that can be run by the [Release] utility.
mixin ReleaseProcess {
  /// Runs the process.
  FutureOr<ReleaseProcessResult> run(Cmd cmd, List<Object> previousValues);

  /// Finds the first success value in the list.
  @protected
  T? findValue<T>(List<Object> previousValues) => previousValues.whereType<T>().firstOrNull;
}

/// The result of a [ReleaseProcess].
sealed class ReleaseProcessResult {
  /// Creates a new [ReleaseProcessResult] instance.
  const ReleaseProcessResult();
}

/// The result of a successful [ReleaseProcess].
class ReleaseProcessResultSuccess<T> extends ReleaseProcessResult {
  /// The value of the result.
  final T value;

  /// Creates a new [ReleaseProcessResultSuccess] instance.
  const ReleaseProcessResultSuccess({
    required this.value,
  });
}

/// The result of a cancelled [ReleaseProcess].
class ReleaseProcessResultCancelled extends ReleaseProcessResult {
  /// Creates a new [ReleaseProcessResultCancelled] instance.
  const ReleaseProcessResultCancelled();
}

/// The result of a failed [ReleaseProcess].
class ReleaseProcessResultError extends ReleaseProcessResult {
  /// The error.
  final dynamic error;

  /// The stack trace.
  final StackTrace stackTrace;

  /// Creates a new [ReleaseProcessResultError] instance.
  ReleaseProcessResultError({
    required this.error,
    StackTrace? stackTrace,
  }) : stackTrace = stackTrace ?? StackTrace.current;
}
