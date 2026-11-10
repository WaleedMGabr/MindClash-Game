import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindclash/features/game/domain/entities/question_entity.dart';

class QuestionModel extends QuestionEntity {
  const QuestionModel({
    required super.questionId,
    required super.question,
    required super.answers,
    required super.correctAnswer,
    super.availableAt,
  });

  factory QuestionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawChoices = data['choices'] ?? data['answers'];
    final choicesList = (rawChoices as List?)?.map((e) => e.toString()).toList() ?? [];

    return QuestionModel(
      questionId: doc.id,
      question: data['question'] as String? ?? '',
      answers: choicesList,
      correctAnswer: data['correctAnswer'] as String? ?? '',
      availableAt: (data['availableAt'] as num?)?.toInt(),
    );
  }

  factory QuestionModel.fromMap(Map<dynamic, dynamic> map) {
    final rawChoices = map['choices'] ?? map['answers'];
    final choicesList = (rawChoices as List?)?.map((e) => e.toString()).toList() ?? [];

    return QuestionModel(
      questionId: map['questionId'] as String? ?? '',
      question: map['question'] as String? ?? '',
      answers: choicesList,
      correctAnswer: map['correctAnswer'] as String? ?? '',
      availableAt: (map['availableAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'question': question,
      'answers': answers,
      'correctAnswer': correctAnswer,
      if (availableAt != null) 'availableAt': availableAt,
    };
  }
}