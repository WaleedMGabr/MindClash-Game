part of 'game_room_cubit.dart';

@immutable
sealed class GameRoomState {}

final class GameRoomInitial extends GameRoomState {}

final class GameRoomLoading extends GameRoomState {}

final class GameRoomSuccess extends GameRoomState {
  final RoomEntity room;

  GameRoomSuccess(this.room);
}

final class GameRoomLeaving extends GameRoomState {}

final class GameRoomClosed extends GameRoomState {}

final class GameRoomError extends GameRoomState {
  final String msg;

  GameRoomError(this.msg);
}
