import 'package:dartz/dartz.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game/domain/entities/question_entity.dart';
import 'package:mindclash/features/game/domain/entities/round_entity.dart';

abstract class GameRepository {
  /// Fetches 10 eligible questions from Firestore and locks them for 10 days
  Future<Either<Failure, List<QuestionEntity>>> loadAndLockQuestions();

  /// Gets the 10 questions stored in RTDB for this match
  Future<Either<Failure, List<QuestionEntity>>> getRoomQuestions(String roomId);

  /// Listens to real-time round changes
  Stream<Either<Failure, RoundEntity?>> watchCurrentRound(String roomId);

  /// Trapper plants 2 traps (within 60s) -> creates 4 choices
  Future<Either<Failure, void>> submitTraps(String roomId, String trap1, String trap2, QuestionEntity question);

  /// Trapper 60s timeout -> creates 2 choices fallback (1 correct + 1 system)
  Future<Either<Failure, void>> handleTrapperTimeout(String roomId, QuestionEntity question);

  /// Answerer submits answer (30s) -> atomically scores and moves to roundResult
  Future<Either<Failure, void>> submitUserAnswer(String roomId, String playerId, String answer);

  /// Advances to next round with role alternation or ends match
  Future<Either<Failure, void>> nextRound(String roomId);
}