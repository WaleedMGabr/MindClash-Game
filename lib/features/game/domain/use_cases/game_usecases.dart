import 'package:dartz/dartz.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game/domain/entities/question_entity.dart';
import 'package:mindclash/features/game/domain/entities/round_entity.dart';
import 'package:mindclash/features/game/domain/repositories/game_repository.dart';

class LoadAndLockQuestionsUseCase {
  final GameRepository gameRepository;
  LoadAndLockQuestionsUseCase(this.gameRepository);

  Future<Either<Failure, List<QuestionEntity>>> call() {
    return gameRepository.loadAndLockQuestions();
  }
}

class GetRoomQuestionsUseCase {
  final GameRepository gameRepository;
  GetRoomQuestionsUseCase(this.gameRepository);

  Future<Either<Failure, List<QuestionEntity>>> call(String roomId) {
    return gameRepository.getRoomQuestions(roomId);
  }
}

class WatchCurrentRoundUseCase {
  final GameRepository gameRepository;
  WatchCurrentRoundUseCase(this.gameRepository);

  Stream<Either<Failure, RoundEntity?>> call(String roomId) {
    return gameRepository.watchCurrentRound(roomId);
  }
}

class SubmitTrapsUseCase {
  final GameRepository gameRepository;
  SubmitTrapsUseCase(this.gameRepository);

  Future<Either<Failure, void>> call(String roomId, String trap1, String trap2, QuestionEntity question) {
    return gameRepository.submitTraps(roomId, trap1, trap2, question);
  }
}

class HandleTrapperTimeoutUseCase {
  final GameRepository gameRepository;
  HandleTrapperTimeoutUseCase(this.gameRepository);

  Future<Either<Failure, void>> call(String roomId, QuestionEntity question) {
    return gameRepository.handleTrapperTimeout(roomId, question);
  }
}

class SubmitUserAnswerUseCase {
  final GameRepository gameRepository;
  SubmitUserAnswerUseCase(this.gameRepository);

  Future<Either<Failure, void>> call(String roomId, String playerId, String answer) {
    return gameRepository.submitUserAnswer(roomId, playerId, answer);
  }
}

class NextRoundUseCase {
  final GameRepository gameRepository;
  NextRoundUseCase(this.gameRepository);

  Future<Either<Failure, void>> call(String roomId) {
    return gameRepository.nextRound(roomId);
  }
}