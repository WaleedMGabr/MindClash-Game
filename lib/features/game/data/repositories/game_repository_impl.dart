import 'package:dartz/dartz.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game/data/datasources/game_remote_datasource.dart';
import 'package:mindclash/features/game/data/models/question_model.dart';
import 'package:mindclash/features/game/domain/entities/question_entity.dart';
import 'package:mindclash/features/game/domain/entities/round_entity.dart';
import 'package:mindclash/features/game/domain/repositories/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  final GameRemoteDatasource gameRemoteDatasource;

  GameRepositoryImpl({required this.gameRemoteDatasource});

  @override
  Future<Either<Failure, List<QuestionEntity>>> loadAndLockQuestions() async {
    try {
      final questions = await gameRemoteDatasource.loadAndLockQuestions();
      return Right(questions);
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuestionEntity>>> getRoomQuestions(String roomId) async {
    try {
      final questions = await gameRemoteDatasource.getRoomQuestions(roomId);
      return Right(questions);
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, RoundEntity?>> watchCurrentRound(String roomId) {
    return gameRemoteDatasource.watchCurrentRound(roomId).map(
          (round) => Right<Failure, RoundEntity?>(round),
        ).handleError(
          (error) => Left<Failure, RoundEntity?>(ServerFailures(error.toString())),
        );
  }

  @override
  Future<Either<Failure, void>> submitTraps(
    String roomId,
    String trap1,
    String trap2,
    QuestionEntity question,
  ) async {
    try {
      final qModel = QuestionModel(
        questionId: question.questionId,
        question: question.question,
        answers: question.answers,
        correctAnswer: question.correctAnswer,
        availableAt: question.availableAt,
      );
      await gameRemoteDatasource.submitTraps(roomId, trap1, trap2, qModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> handleTrapperTimeout(
    String roomId,
    QuestionEntity question,
  ) async {
    try {
      final qModel = QuestionModel(
        questionId: question.questionId,
        question: question.question,
        answers: question.answers,
        correctAnswer: question.correctAnswer,
        availableAt: question.availableAt,
      );
      await gameRemoteDatasource.handleTrapperTimeout(roomId, qModel);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitUserAnswer(
    String roomId,
    String playerId,
    String answer,
  ) async {
    try {
      await gameRemoteDatasource.submitUserAnswer(roomId, playerId, answer);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> nextRound(String roomId) async {
    try {
      await gameRemoteDatasource.nextRound(roomId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }
}