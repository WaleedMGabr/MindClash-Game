
import 'package:mindclash/features/game_room/data/models/player_model.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.roomId,
    required super.code,
    required super.hostId,
    required super.roomStatus,
    required super.players,
    super.currentQuestionIndex,
  });

  factory RoomModel.fromMap(Map<dynamic, dynamic> map) {
    final rawPlayers = map['players'];
    final Map<String, PlayerModel> parsedPlayers = {};

    if (rawPlayers is Map) {
      rawPlayers.forEach((key, value) {
        if (value is Map) {
          parsedPlayers[key.toString()] = PlayerModel.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    return RoomModel(
      roomId: map['roomId'] as String? ?? '',
      code: map['code'] as String? ?? '',
      hostId: map['hostId'] as String? ?? '',
      roomStatus: RoomStatus.values.firstWhere(
            (status) => status.name == map['roomStatus'],
        orElse: () => RoomStatus.waiting,
      ),
      players: parsedPlayers,
      currentQuestionIndex:
      (map['currentQuestionIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'code': code,
      'hostId': hostId,
      'roomStatus': roomStatus.name,
      'players': players.map(
            (key, player) => MapEntry(
          key,
          PlayerModel(
            playerId: player.playerId,
            username: player.username,
            score: player.score,
            isReady: player.isReady,
          ).toMap(),
        ),
      ),
      'currentQuestionIndex': currentQuestionIndex,
    };
  }
}
