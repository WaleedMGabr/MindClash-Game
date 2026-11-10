import 'package:equatable/equatable.dart';

class QuestionEntity extends Equatable{
  final String questionId;
  final String question;
  final List<String> answers;
  final String correctAnswer;
  final int? availableAt;

  const QuestionEntity({
    required this.questionId,
    required this.question,
    required this.answers,
    required this.correctAnswer,
    this.availableAt,
  });

  @override
  List<Object?> get props => [questionId, question, answers, correctAnswer, availableAt];

}