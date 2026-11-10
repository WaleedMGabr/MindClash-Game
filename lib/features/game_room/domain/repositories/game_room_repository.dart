import 'package:dartz/dartz.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';

abstract class GameRoomRepository {
  Future<Either<Failure, RoomEntity>> createRoom();
  Future<Either<Failure, RoomEntity>> joinRoom(String code);
  Future<Either<Failure, void>> leaveRoom(String roomId);
  Future<Either<Failure, void>> PlayerReady(String userId , String roomId);
  Stream<Either<Failure, RoomEntity?>> watchRoom(String roomId);
}