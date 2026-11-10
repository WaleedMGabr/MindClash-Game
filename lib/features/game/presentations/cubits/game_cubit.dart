.import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindclash/features/game/domain/entities/question_entity.dart';
import 'package:mindclash/features/game/domain/entities/round_entity.dart';
import 'package:mindclash/features/game/domain/use_cases/game_usecases.dart';
import 'package:mindclash/features/game/presentations/cubits/game_state.dart';

class GameCubit extends Cubit<GameState> {
  final WatchCurrentRoundUseCase watchCurrentRoundUseCase;
  final GetRoomQuestionsUseCase getRoomQuestionsUseCase;
  final SubmitTrapsUseCase submitTrapsUseCase;
  final HandleTrapperTimeoutUseCase handleTrapperTimeoutUseCase;
  final SubmitUserAnswerUseCase submitUserAnswerUseCase;
  final NextRoundUseCase nextRoundUseCase;

  StreamSubscription? _roundSubscription;
  Timer? _countdownTimer;
  String? _roomId;
  String? _currentUserId;
  List<QuestionEntity> _questions = [];
  bool _isProcessingTimeout = false;

  GameCubit({
    required this.watchCurrentRoundUseCase,
    required this.getRoomQuestionsUseCase,
    required this.submitTrapsUseCase,
    required this.handleTrapperTimeoutUseCase,
    required this.submitUserAnswerUseCase,
    required this.nextRoundUseCase,
  }) : super(const GameInitial());

  Future<void> initGame({
    required String roomId,
    required String currentUserId,
  }) async {
    _roomId = roomId;
    _currentUserId = currentUserId;

    emit(const GameLoading());

    // 1. Fetch the 10 questions of the room
    final questionsResult = await getRoomQuestionsUseCase(roomId);
    questionsResult.fold(
      (failure) => emit(GameError(failure.message)),
      (questions) {
        _questions = questions;
      },
    );

    // 2. Listen to real-time round changes
    await _roundSubscription?.cancel();
    _roundSubscription = watchCurrentRoundUseCase(roomId).listen(
      (roundResult) {
        roundResult.fold(
          (failure) => emit(GameError(failure.message)),
          (round) {
            if (round == null) return;

            if (round.roundIndex >= 10) {
              _countdownTimer?.cancel();
              emit(GameOverState(roomId: roomId));
              return;
            }

            _isProcessingTimeout = false;
            final now = DateTime.now().millisecondsSinceEpoch;
            final remaining = max(0, ((round.phaseDeadline - now) / 1000).ceil());

            emit(GameRoundState(
              round: round,
              questions: _questions,
              currentUserId: currentUserId,
              remainingSeconds: remaining,
            ));

            _startCountdown(round);
          },
        );
      },
      onError: (error) {
        emit(GameError(error.toString()));
      },
    );
  }

  void _startCountdown(RoundEntity round) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is! GameRoundState) {
        timer.cancel();
        return;
      }

      final currentState = state as GameRoundState;
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = max(0, ((round.phaseDeadline - now) / 1000).ceil());

      if (remaining > 0) {
        emit(currentState.copyWith(remainingSeconds: remaining));
      } else {
        timer.cancel();
        emit(currentState.copyWith(remainingSeconds: 0));
        _handleTimerExpired(currentState);
      }
    });
  }

  void _handleTimerExpired(GameRoundState currentState) async {
    if (_isProcessingTimeout) return;
    _isProcessingTimeout = true;

    final round = currentState.round;
    final roomId = _roomId;
    if (roomId == null) {
      _isProcessingTimeout = false;
      return;
    }

    final question = currentState.currentQuestion ??
        (round.question.isNotEmpty
            ? QuestionEntity(
                questionId: 'q_${round.roundIndex}',
                question: round.question,
                correctAnswer: round.correctAnswer,
                answers: const ['اختيار خاطئ'],
              )
            : null);

    try {
      if (round.roundStatus == RoundStatus.settingTrapper) {
        if (question == null) {
          _isProcessingTimeout = false;
          return;
        }
        if (currentState.isTrapper) {
          final res = await handleTrapperTimeoutUseCase(roomId, question);
          res.fold((failure) => _isProcessingTimeout = false, (_) => null);
        } else {
          Future.delayed(const Duration(seconds: 2), () async {
            if (state is GameRoundState &&
                (state as GameRoundState).round.roundStatus == RoundStatus.settingTrapper) {
              final res = await handleTrapperTimeoutUseCase(roomId, question);
              res.fold((failure) => _isProcessingTimeout = false, (_) => null);
            }
          });
        }
      } else if (round.roundStatus == RoundStatus.playerAnswer) {
        if (currentState.isAnswerer) {
          final res = await submitUserAnswerUseCase(roomId, _currentUserId ?? '', '');
          res.fold((failure) => _isProcessingTimeout = false, (_) => null);
        } else {
          Future.delayed(const Duration(seconds: 2), () async {
            if (state is GameRoundState &&
                (state as GameRoundState).round.roundStatus == RoundStatus.playerAnswer) {
              final res = await submitUserAnswerUseCase(roomId, round.answererId, '');
              res.fold((failure) => _isProcessingTimeout = false, (_) => null);
            }
          });
        }
      } else if (round.roundStatus == RoundStatus.roundResult) {
        if (currentState.isTrapper) {
          final res = await nextRoundUseCase(roomId);
          res.fold((failure) => _isProcessingTimeout = false, (_) => null);
        } else {
          Future.delayed(const Duration(seconds: 1), () async {
            if (state is GameRoundState &&
                (state as GameRoundState).round.roundStatus == RoundStatus.roundResult) {
              final res = await nextRoundUseCase(roomId);
              res.fold((failure) => _isProcessingTimeout = false, (_) => null);
            }
          });
        }
      }
    } catch (_) {
      _isProcessingTimeout = false;
    }
  }

  Future<void> submitTraps(String trap1, String trap2) async {
    if (state is! GameRoundState) return;
    final currentState = state as GameRoundState;
    final roomId = _roomId;
    final question = currentState.currentQuestion;

    if (roomId == null || question == null) return;

    final t1 = trap1.trim();
    final t2 = trap2.trim();

    if (t1.isEmpty || t2.isEmpty) {
      emit(currentState.copyWith(errorMessage: 'يرجى كتابة الفخين معاً'));
      return;
    }

    if (t1.toLowerCase() == t2.toLowerCase()) {
      emit(currentState.copyWith(errorMessage: 'ممنوع كتابة فخين متطابقين أو متشابهين!'));
      return;
    }

    final t1Lower = t1.toLowerCase();
    final t2Lower = t2.toLowerCase();
    final correctLower = question.correctAnswer.trim().toLowerCase();

    if (t1Lower == correctLower || t2Lower == correctLower) {
      emit(currentState.copyWith(errorMessage: 'لقد كتبت الإجابة الصحيحة! الفخ يجب أن يكون إجابة خاطئة'));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, errorMessage: null));

    final result = await submitTrapsUseCase(roomId, t1, t2, question);
    result.fold(
      (failure) {
        if (state is GameRoundState) {
          emit((state as GameRoundState).copyWith(isSubmitting: false, errorMessage: failure.message));
        }
      },
      (_) {
        if (state is GameRoundState) {
          emit((state as GameRoundState).copyWith(isSubmitting: false, errorMessage: null));
        }
      },
    );
  }

  Future<void> submitAnswer(String answer) async {
    if (state is! GameRoundState) return;
    final currentState = state as GameRoundState;
    final roomId = _roomId;
    final userId = _currentUserId;

    if (roomId == null || userId == null) return;

    emit(currentState.copyWith(isSubmitting: true, errorMessage: null));

    final result = await submitUserAnswerUseCase(roomId, userId, answer);
    result.fold(
      (failure) {
        if (state is GameRoundState) {
          emit((state as GameRoundState).copyWith(isSubmitting: false, errorMessage: failure.message));
        }
      },
      (_) {
        if (state is GameRoundState) {
          emit((state as GameRoundState).copyWith(isSubmitting: false, errorMessage: null));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _roundSubscription?.cancel();
    return super.close();
  }
}
