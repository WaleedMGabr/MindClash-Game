
import 'package:equatable/equatable.dart';

class PlayerEntity extends Equatable{
  final String playerId;
  final String username;
  final int score;
  final bool isReady;

  const PlayerEntity({required this.playerId, required this.username, this.score = 0, this.isReady = false});

  @override
  List<Object?> get props => [playerId, username, score, isReady];
}