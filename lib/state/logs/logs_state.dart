import 'package:done_today/storage/models/log_model.dart';
import 'package:done_today/storage/models/log_stats_model.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class LogsState {}

class LogsInitial extends LogsState {}

class LogsLoading extends LogsState {}

class LogsLoaded extends LogsState {
  final List<Log> logs;
  final LogStats? stats;

  LogsLoaded(this.logs, {this.stats});
}

class LogsError extends LogsState {
  final String message;

  LogsError(this.message);
}
