import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mindclash/core/errors/exceptions.dart';
import 'package:mindclash/features/game/data/models/question_model.dart';
import 'package:mindclash/features/game/data/models/round_model.dart';
import 'package:mindclash/features/game/domain/entities/round_entity.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';

abstract class GameRemoteDatasource {
  Future<List<QuestionModel>> loadAndLockQuestions();
  Future<List<QuestionModel>> getRoomQuestions(String roomId);
  Stream<RoundModel?> watchCurrentRound(String roomId);
  Future<void> submitTraps(String roomId, String trap1, String trap2, QuestionModel question);
  Future<void> handleTrapperTimeout(String roomId, QuestionModel question);
  Future<void> submitUserAnswer(String roomId, String playerId, String answer);
  Future<void> nextRound(String roomId);
}

class GameRemoteDatasourceImpl implements GameRemoteDatasource {
  final FirebaseFirestore firebaseFirestore;
  final FirebaseDatabase firebaseDatabase;

  GameRemoteDatasourceImpl({
    required this.firebaseFirestore,
    required this.firebaseDatabase,
  });

  @override
  Future<List<QuestionModel>> getRoomQuestions(String roomId) async {
    try {
      final snapshot = await firebaseDatabase.ref('rooms/$roomId/questions').get();
      if (!snapshot.exists || snapshot.value is! List) {
        return [];
      }
      final list = snapshot.value as List;
      return list
          .whereType<Map>()
          .map((item) => QuestionModel.fromMap(Map<dynamic, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<QuestionModel>> loadAndLockQuestions() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final querySnapshot = await firebaseFirestore.collection('questions').get();
      if (querySnapshot.docs.isEmpty) {
        throw const ServerException('No questions found in questions collection.');
      }

      // 1. Filter questions where availableAt is null OR availableAt <= now
      final eligibleDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final availableAt = data['availableAt'] as num?;
        return availableAt == null || availableAt <= now;
      }).toList();

      List<QueryDocumentSnapshot<Map<String, dynamic>>> selectedDocs;
      if (eligibleDocs.length >= 10) {
        eligibleDocs.shuffle(Random());
        selectedDocs = eligibleDocs.take(10).toList();
      } else {
        // Fallback: sort all questions by availableAt ascending (least recently used)
        final allDocs = [...querySnapshot.docs];
        allDocs.sort((a, b) {
          final aTime = (a.data()['availableAt'] as num?) ?? 0;
          final bTime = (b.data()['availableAt'] as num?) ?? 0;
          return aTime.compareTo(bTime);
        });
        selectedDocs = allDocs.take(10).toList();
      }

      // 2. Lock selected 10 questions for 10 days in Firestore
      final tenDaysLater = DateTime.now().add(const Duration(days: 10)).millisecondsSinceEpoch;
      final batch = firebaseFirestore.batch();
      for (final doc in selectedDocs) {
        batch.update(doc.reference, {
          'availableAt': tenDaysLater,
          'lastUsedAt': now,
        });
      }
      await batch.commit();

      return selectedDocs.map((doc) => QuestionModel.fromFirestore(doc)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<RoundModel?> watchCurrentRound(String roomId) {
    return firebaseDatabase.ref('rooms/$roomId/currentRound').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) {
        return null;
      }
      return RoundModel.fromMap(Map<dynamic, dynamic>.from(value));
    });
  }

  @override
  Future<void> submitTraps(
    String roomId,
    String trap1,
    String trap2,
    QuestionModel question,
  ) async {
    try {
      final random = Random();
      final t1Trimmed = trap1.trim().toLowerCase();
      final t2Trimmed = trap2.trim().toLowerCase();

      // Filter system choices to exclude anything the trapper entered
      final remainingSystemChoices = question.answers.where((choice) {
        final choiceLower = choice.trim().toLowerCase();
        return choiceLower != t1Trimmed && choiceLower != t2Trimmed;
      }).toList();

      final systemChoice = remainingSystemChoices.isNotEmpty
          ? remainingSystemChoices[random.nextInt(remainingSystemChoices.length)]
          : (question.answers.isNotEmpty ? question.answers[0] : 'اختيار خاطئ');

      // Assemble 4 choices: 1 correct + 2 traps + 1 system wrong
      final List<Map<String, Trapper>> options = [
        {question.correctAnswer: Trapper.correct},
        {trap1: Trapper.rival},
        {trap2: Trapper.rival},
        {systemChoice: Trapper.system},
      ]..shuffle(random);

      // Answering deadline: 30 seconds
      final deadline = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;

      final roundRef = firebaseDatabase.ref('rooms/$roomId/currentRound');
      await roundRef.update({
        'roundStatus': RoundStatus.playerAnswer.name,
        'currentChoices': options.map((m) => {
          'text': m.keys.first,
          'type': m.values.first.name,
        }).toList(),
        'phaseDeadline': deadline,
        'isTrapperTimedOut': false,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> handleTrapperTimeout(String roomId, QuestionModel question) async {
    try {
      final random = Random();
      // Trapper timed out -> only 2 choices: 1 correct + 1 system wrong
      final systemChoice = question.answers.isNotEmpty
          ? question.answers[random.nextInt(question.answers.length)]
          : 'اختيار خاطئ';

      final List<Map<String, Trapper>> options = [
        {question.correctAnswer: Trapper.correct},
        {systemChoice: Trapper.system},
      ]..shuffle(random);

      // Answering deadline: 30 seconds
      final deadline = DateTime.now().add(const Duration(seconds: 30)).millisecondsSinceEpoch;

      final roundRef = firebaseDatabase.ref('rooms/$roomId/currentRound');
      await roundRef.update({
        'roundStatus': RoundStatus.playerAnswer.name,
        'currentChoices': options.map((m) => {
          'text': m.keys.first,
          'type': m.values.first.name,
        }).toList(),
        'phaseDeadline': deadline,
        'isTrapperTimedOut': true,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> submitUserAnswer(String roomId, String playerId, String answer) async {
    try {
      final roundRef = firebaseDatabase.ref('rooms/$roomId/currentRound');
      final snapshot = await roundRef.get();
      if (!snapshot.exists || snapshot.value is! Map) {
        throw const ServerException('Round not found');
      }

      final roundMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final rawChoices = roundMap['currentChoices'];
      final trapperId = roundMap['trapperId']?.toString() ?? '';

      // Determine answer type
      Trapper selectedType = Trapper.system;
      if (rawChoices is List) {
        for (final item in rawChoices) {
          if (item is Map) {
            if (item.containsKey('text') && item['text']?.toString() == answer) {
              final typeStr = item['type']?.toString();
              selectedType = Trapper.values.firstWhere(
                (t) => t.name == typeStr,
                orElse: () => Trapper.system,
              );
              break;
            } else if (item.containsKey(answer)) {
              final typeStr = item[answer]?.toString();
              selectedType = Trapper.values.firstWhere(
                (t) => t.name == typeStr,
                orElse: () => Trapper.system,
              );
              break;
            }
          }
        }
      }

      String? awardedTo;
      if (selectedType == Trapper.correct) {
        // Answerer gets +1 point
        awardedTo = 'answerer';
        final scoreRef = firebaseDatabase.ref('rooms/$roomId/players/$playerId/score');
        final currentScore = (await scoreRef.get()).value as num? ?? 0;
        await scoreRef.set(currentScore + 1);
      } else if (selectedType == Trapper.rival) {
        // Trapper gets +1 point
        awardedTo = 'trapper';
        if (trapperId.isNotEmpty) {
          final scoreRef = firebaseDatabase.ref('rooms/$roomId/players/$trapperId/score');
          final currentScore = (await scoreRef.get()).value as num? ?? 0;
          await scoreRef.set(currentScore + 1);
        }
      } else {
        // System wrong -> 0 points
        awardedTo = 'none';
      }

      // Transition to roundResult for 4 seconds
      final deadline = DateTime.now().add(const Duration(seconds: 4)).millisecondsSinceEpoch;
      await roundRef.update({
        'playerAnswer': answer,
        'roundStatus': RoundStatus.roundResult.name,
        'awardedTo': awardedTo,
        'phaseDeadline': deadline,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> nextRound(String roomId) async {
    try {
      final roomRef = firebaseDatabase.ref('rooms/$roomId');
      final snapshot = await roomRef.get();
      if (!snapshot.exists || snapshot.value is! Map) {
        throw const ServerException('Room not found');
      }

      final roomMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final currentIndex = (roomMap['currentQuestionIndex'] as num?)?.toInt() ?? 0;
      final nextIndex = currentIndex + 1;

      // If finished all 10 rounds -> game over
      if (nextIndex >= 10) {
        await roomRef.update({
          'roomStatus': RoomStatus.finished.name,
        });
        return;
      }

      // Load next question from room's questions list
      final rawQuestions = roomMap['questions'];
      if (rawQuestions is! List || nextIndex >= rawQuestions.length) {
        await roomRef.update({
          'roomStatus': RoomStatus.finished.name,
        });
        return;
      }

      final nextQuestionMap = Map<dynamic, dynamic>.from(rawQuestions[nextIndex] as Map);
      final nextQuestion = QuestionModel.fromMap(nextQuestionMap);

      // Swap roles: previous answerer becomes trapper, previous trapper becomes answerer
      final currentRoundMap = roomMap['currentRound'] is Map
          ? Map<dynamic, dynamic>.from(roomMap['currentRound'] as Map)
          : {};
      final previousTrapperId = currentRoundMap['trapperId']?.toString() ?? '';
      final previousAnswererId = currentRoundMap['answererId']?.toString() ?? '';

      final newTrapperId = previousAnswererId.isNotEmpty ? previousAnswererId : previousTrapperId;
      final newAnswererId = previousTrapperId;

      // 60 seconds for Trap phase
      final deadline = DateTime.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch;

      final nextRound = RoundModel(
        roundIndex: nextIndex,
        question: nextQuestion.question,
        trapperId: newTrapperId,
        answererId: newAnswererId,
        roundStatus: RoundStatus.settingTrapper,
        currentChoices: const [],
        playerAnswer: '',
        correctAnswer: nextQuestion.correctAnswer,
        phaseDeadline: deadline,
        awardedTo: null,
        isTrapperTimedOut: false,
      );

      await roomRef.update({
        'currentQuestionIndex': nextIndex,
        'currentRound': nextRound.toMap(),
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}