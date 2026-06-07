import 'package:done_today/storage/models/challenge.dart';
import 'package:done_today/storage/models/log_model.dart';

abstract class ChallengesState {}

class ChallengesInitial extends ChallengesState {}

class ChallengesLoading extends ChallengesState {}

class ChallengesLoaded extends ChallengesState {
  final List<Challenge> challenges;
  final Map<String, List<Log>> challengeLogs; // challengeId -> logs

  ChallengesLoaded({
    required this.challenges,
    this.challengeLogs = const {},
  });
}

class ChallengesError extends ChallengesState {
  final String message;
  ChallengesError(this.message);
}
