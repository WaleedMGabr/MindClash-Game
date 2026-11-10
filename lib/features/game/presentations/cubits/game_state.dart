import 'package:equatable/equatable.dart';
import 'package:mindclash/features/game/domain/entities/question_entity.dart';
import 'package:mindclash/features/game/domain/entities/round_entity.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameLoading extends GameState {
  const GameLoading();
}

class GameRoundState extends GameState {
  final RoundEntity round;
  final List<QuestionEntity> questions;
  final String currentUserId;
  final int remainingSeconds;
  final bool isSubmitting;
  final String? errorMessage;

  const GameRoundState({
    required this.round,
    required this.questions,
    required this.currentUserId,
    required this.remainingSeconds,
    this.isSubmitting = false,
    this.errorMessage,
  });

  bool get isTrapper => currentUserId == round.trapperId;
  bool get isAnswerer => currentUserId == round.answererId;

  QuestionEntity? get currentQuestion {
    if (round.roundIndex >= 0 && round.roundIndex < questions.length) {
      return questions[round.roundIndex];
    }
    return null;
  }

  GameRoundState copyWith({
    RoundEntity? round,
    List<QuestionEntity>? questions,
    String? currentUserId,
    int? remainingSeconds,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return GameRoundState(
      round: round ?? this.round,
      questions: questions ?? this.questions,
      currentUserId: currentUserId ?? this.currentUserId,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        round,
        questions,
        currentUserId,
        remainingSeconds,
        isSubmitting,
        errorMessage,
      ];
}

class GameOverState extends GameState {
  final String roomId;
  const GameOverState({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class GameError extends GameState {
  final String message;
  const GameError(this.message);

  @override
  List<Object?> get props => [message];
}
