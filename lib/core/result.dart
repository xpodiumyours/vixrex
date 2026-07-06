import 'package:vixrex/utils/failure.dart';

class Result<T> {
  final T? _data;
  final Failure? _failure;

  bool get isSuccess => _failure == null;
  bool get isFailure => _failure != null;
  T? get data => _data;
  Failure? get failure => _failure;

  const Result.success(T data)
      : _data = data,
        _failure = null;

  const Result.failure(Failure failure)
      : _data = null,
        _failure = failure;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    if (isSuccess) {
      return success(_data as T);
    } else {
      return failure(_failure!);
    }
  }
}
