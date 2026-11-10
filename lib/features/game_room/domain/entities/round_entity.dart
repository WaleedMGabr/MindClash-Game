import 'package:equatable/equatable.dart';

enum RoundStatus{
  settingTrap,
  playing
}

class RoundEntity extends Equatable {
  final RoundStatus roundStatus;
  final String trapSetterId;
  final String answererId;
  final DateTime deadline;

  const RoundEntity({required this.roundStatus, required this.trapSetterId, required this.answererId, required this.deadline});

  @override
  List<Object?> get props => [roundStatus, trapSetterId, answererId, deadline];
}
