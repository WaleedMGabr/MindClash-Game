import 'package:flutter_test/flutter_test.dart';
import 'package:mindclash/features/game_room/data/models/player_model.dart';
import 'package:mindclash/features/game_room/data/models/room_model.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';

void main() {
  group('RoomModel Tests', () {
    const testPlayer = PlayerModel(
      playerId: 'user_1',
      username: 'Player1',
      score: 10,
    );

    const testRoomModel = RoomModel(
      roomId: '-N123456789',
      code: '654321',
      hostId: 'user_1',
      roomStatus: RoomStatus.waiting,
      players: {'user_1': testPlayer},
      currentQuestionIndex: 0,
    );

    test('toMap converts RoomModel into valid JSON-compatible Map', () {
      final map = testRoomModel.toMap();

      expect(map['roomId'], '-N123456789');
      expect(map['code'], '654321');
      expect(map['hostId'], 'user_1');
      // roomStatus must be string name, not enum instance
      expect(map['roomStatus'], 'waiting');
      expect(map['roomStatus'] is String, true);
      // players must be a map of primitives/maps
      expect(map['players'], isA<Map<String, dynamic>>());
      expect(map['players']['user_1']['playerId'], 'user_1');
      expect(map['players']['user_1']['username'], 'Player1');
      expect(map['players']['user_1']['score'], 10);
    });

    test('fromMap restores RoomModel from Map correctly', () {
      final map = {
        'roomId': '-N123456789',
        'code': '654321',
        'hostId': 'user_1',
        'roomStatus': 'waiting',
        'players': {
          'user_1': {
            'playerId': 'user_1',
            'username': 'Player1',
            'score': 10,
          }
        },
        'currentQuestionIndex': 2,
      };

      final result = RoomModel.fromMap(map);

      expect(result.roomId, '-N123456789');
      expect(result.code, '654321');
      expect(result.roomStatus, RoomStatus.waiting);
      expect(result.currentQuestionIndex, 2);
      expect(result.players.length, 1);
      expect(result.players['user_1']?.username, 'Player1');
    });
  });
}
