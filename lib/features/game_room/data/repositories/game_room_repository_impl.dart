import 'package:dartz/dartz.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game_room/data/datasources/game_room_remote_datasource.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';
import 'package:mindclash/features/game_room/domain/repositories/game_room_repository.dart';

class GameRoomRepositoryImpl implements GameRoomRepository {
  final GameRoomRemoteDatasource gameRoomRemoteDatasource;

  GameRoomRepositoryImpl(this.gameRoomRemoteDatasource);

  @override
  Future<Either<Failure, RoomEntity>> createRoom() async {
    try {
      final room = await gameRoomRemoteDatasource.createRoom();
      return Right(room);
    } catch (e) {
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomEntity>> joinRoom(String code) async{
    try{
      final room = await gameRoomRemoteDatasource.joinRoom(code);
      return Right(room);
    }catch(e){
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveRoom(String roomId) async {
    try{
      await gameRoomRemoteDatasource.leaveRoom(roomId);
      return const Right(null);
    }catch(e){
      return Left(ServerFailures(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, RoomEntity?>> watchRoom(String roomId) async* {
    try {
      await for (final room in gameRoomRemoteDatasource.watchRoom(roomId)) {
        yield Right(room);
      }
    }catch(e){
      yield Left(ServerFailures(e.toString()));
      /// yield => async*
    }
  }

  @override
  Future<Either<Failure, void>> PlayerReady(String userId , String roomId) async{
    try{
      await gameRoomRemoteDatasource.PlayerReady(userId , roomId);
      return const Right(null);
    }catch(e){
      return Left(ServerFailures(e.toString()));
    }
  }
}