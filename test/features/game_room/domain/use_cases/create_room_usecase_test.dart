import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game_room/domain/entities/player_entity.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';
import 'package:mindclash/features/game_room/domain/repositories/game_room_repository.dart';
import 'package:mindclash/features/game_room/domain/use_cases/game_room_usecases.dart';

class MockGameRoomRepository implements GameRoomRepository {
  final Either<Failure, RoomEntity> result;

  MockGameRoomRepository(this.result);

  @override
  Future<Either<Failure, RoomEntity>> createRoom() async {
    return result;
  }

  @override
  Future<Either<Failure, RoomEntity>> joinRoom(String code) => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> leaveRoom(String roomId) => throw UnimplementedError();

  @override
  Stream<Either<Failure, RoomEntity?>> watchRoom(String roomId) => throw UnimplementedError();
}

void main() {
  const testRoom = RoomEntity(
    roomId: 'room_123',
    code: '999888',
    hostId: 'user_1',
    roomStatus: RoomStatus.waiting,
    players: {'user_1': PlayerEntity(playerId: 'user_1', username: 'Tester')},
  );

  test('CreateRoomUseCase should delegate call to repository and return room', () async {
    final mockRepo = MockGameRoomRepository(const Right(testRoom));
    final useCase = CreateRoomUseCase(mockRepo);

    final result = await useCase();

    expect(result, const Right(testRoom));
  });

  test('CreateRoomUseCase should return failure when repository fails', () async {
    const failure = ServerFailures('Failed to create room');
    final mockRepo = MockGameRoomRepository(const Left(failure));
    final useCase = CreateRoomUseCase(mockRepo);

    final result = await useCase();

    expect(result, const Left(failure));
  });
}
