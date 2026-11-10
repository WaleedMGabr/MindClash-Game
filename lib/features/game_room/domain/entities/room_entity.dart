import 'package:equatable/equatable.dart';
import 'package:mindclash/features/game_room/domain/entities/player_entity.dart';

enum RoomStatus{
  waiting,
  playing,
  finished,
}

class RoomEntity extends Equatable {
  final String roomId;
  final String code;
  final String hostId;
  final RoomStatus roomStatus;
  final Map<String, PlayerEntity> players;
  final int currentQuestionIndex;
  // final RoundEntity? currentRound;

  const RoomEntity({required this.roomId, required this.code, required this.hostId, required this.roomStatus, required this.players, this.currentQuestionIndex = 0});

  @override
  // TODO: implement props
  List<Object?> get props => [roomId, code, hostId, roomStatus, players, currentQuestionIndex];
}

