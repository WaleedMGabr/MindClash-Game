import 'package:flutter_test/flutter_test.dart';
import 'package:mindclash/core/errors/exceptions.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game_room/data/datasources/game_room_remote_datasource.dart';
import 'package:mindclash/features/game_room/data/models/player_model.dart';
import 'package:mindclash/features/game_room/data/models/room_model.dart';
import 'package:mindclash/features/game_room/data/repositories/game_room_repository_impl.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';

class MockGameRoomRemoteDatasource implements GameRoomRemoteDatasource {
  final RoomModel? roomToReturn;
  final Exception? exceptionToThrow;

  MockGameRoomRemoteDatasource({this.roomToReturn, this.exceptionToThrow});

  @override
  Future<RoomModel> createRoom() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return roomToReturn!;
  }

  @override
  Future<RoomModel> joinRoom(String code) => throw UnimplementedError();

  @override
  Future<void> leaveRoom(String roomId) => throw UnimplementedError();

  @override
  Stream<RoomModel?> watchRoom(String roomId) => throw UnimplementedError();
}

void main() {
  const testPlayer = PlayerModel(playerId: 'host_id', username: 'HostUser');
  const testRoomModel = RoomModel(
    roomId: 'room_abc',
    code: '123456',
    hostId: 'host_id',
    roomStatus: RoomStatus.waiting,
    players: {'host_id': testPlayer},
  );

  test('should return Right(RoomEntity) when datasource succeeds', () async {
    final mockDatasource = MockGameRoomRemoteDatasource(roomToReturn: testRoomModel);
    final repository = GameRoomRepositoryImpl(mockDatasource);

    final result = await repository.createRoom();

    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Expected Right but got Left'),
      (room) {
        expect(room.roomId, 'room_abc');
        expect(room.code, '123456');
        expect(room.hostId, 'host_id');
        expect(room.roomStatus, RoomStatus.waiting);
      },
    );
  });

  test('should return Left(ServerFailures) when datasource throws ServerException', () async {
    final mockDatasource = MockGameRoomRemoteDatasource(
      exceptionToThrow: const ServerException('Database failure'),
    );
    final repository = GameRoomRepositoryImpl(mockDatasource);

    final result = await repository.createRoom();

    expect(result.isLeft(), true);
    result.fold(
      (failure) {
        expect(failure, isA<ServerFailures>());
        expect(failure.msg, contains('Database failure'));
      },
      (room) => fail('Expected Left but got Right'),
    );
  });
}
