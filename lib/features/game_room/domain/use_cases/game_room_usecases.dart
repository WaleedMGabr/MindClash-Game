import 'package:dartz/dartz.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';
import 'package:mindclash/features/game_room/domain/repositories/game_room_repository.dart';

class CreateRoomUseCase{
  final GameRoomRepository gameRoomRepository;

  CreateRoomUseCase(this.gameRoomRepository);

  Future<Either<Failure, RoomEntity>> call(){
    return gameRoomRepository.createRoom();
  }

}

class JoinRoomUseCase{
  final GameRoomRepository gameRoomRepository;

  JoinRoomUseCase(this.gameRoomRepository);

  Future<Either<Failure,RoomEntity>> call(String code){
    return gameRoomRepository.joinRoom(code);
  }

}

class LeaveRoomUseCase{
  final GameRoomRepository gameRoomRepository;
  LeaveRoomUseCase(this.gameRoomRepository);

  Future<Either<Failure,void>> call(String roomId){
    return gameRoomRepository.leaveRoom(roomId);
  }
}

class WatchRoomUseCase {
  final GameRoomRepository repository;

  WatchRoomUseCase(this.repository);

  Stream<Either<Failure, RoomEntity?>> call(String roomId) {
    return repository.watchRoom(roomId);
  }
}

class PlayerReadyUseCase{
  final GameRoomRepository gameRoomRepository;
  PlayerReadyUseCase(this.gameRoomRepository);
  Future<Either<Failure,void>> call(String userId, String roomId){
    return gameRoomRepository.PlayerReady(userId, roomId);
  }
}