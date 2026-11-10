import 'package:equatable/equatable.dart';

enum RoundStatus {
  settingTrapper,
  playerAnswer,
  roundResult,
}

enum Trapper {
  rival,
  system,
  correct,
}

class RoundEntity extends Equatable {
  final int roundIndex;
  final String question;
  final String trapperId;
  final String answererId;
  final RoundStatus roundStatus;
  final List<Map<String, Trapper>> currentChoices; /// [{"choice": Trapper.correct}, ...]
  final String playerAnswer;
  final String correctAnswer;
  final int phaseDeadline; // epoch milliseconds
  final String? awardedTo; // "trapper", "answerer", or null
  final bool isTrapperTimedOut; // true if 2-choice fallback was triggered

  const RoundEntity({
    this.roundIndex = 0,
    this.question = '',
    required this.trapperId,
    required this.answererId,
    required this.roundStatus,
    required this.currentChoices,
    required this.playerAnswer,
    required this.correctAnswer,
    required this.phaseDeadline,
    this.awardedTo,
    this.isTrapperTimedOut = false,
  });

  @override
  List<Object?> get props => [
        roundIndex,
        question,
        trapperId,
        answererId,
        roundStatus,
        currentChoices,
        playerAnswer,
        correctAnswer,
        phaseDeadline,
        awardedTo,
        isTrapperTimedOut,
      ];
}