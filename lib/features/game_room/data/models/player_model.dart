
import 'package:mindclash/features/game_room/domain/entities/player_entity.dart';

class PlayerModel extends PlayerEntity {
  const PlayerModel({
    required super.playerId,
    required super.username,
    super.score,
    super.isReady
  });

  factory PlayerModel.fromMap(Map<dynamic, dynamic> map) {
    return PlayerModel(
      playerId: map['playerId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      isReady: map['isReady'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'username': username,
      'score': score,
      'isReady': isReady,
    };
  }
}
