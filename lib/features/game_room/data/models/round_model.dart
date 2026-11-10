import 'package:mindclash/features/game_room/domain/entities/round_entity.dart';

class RoundModel extends RoundEntity{
  const RoundModel({required super.roundStatus, required super.trapSetterId, required super.answererId, required super.deadline});

  Map<String, dynamic> toMap() {
    return {
      'roundStatus': roundStatus,
      'trapSetterId': trapSetterId,
      'answererId': answererId,
      'deadline': deadline,
    };
  }

  factory RoundModel.fromMap(Map<String, dynamic> map) {
    return RoundModel(
      roundStatus: map['roundStatus'],
      trapSetterId: map['trapSetterId'],
      answererId: map['answererId'],
      deadline: map['deadline'],
    );

  }
}