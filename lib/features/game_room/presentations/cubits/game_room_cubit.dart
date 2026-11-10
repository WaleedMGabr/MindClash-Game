import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';
import 'package:mindclash/core/errors/failures.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';
import 'package:mindclash/features/game_room/domain/use_cases/game_room_usecases.dart';

part 'game_room_state.dart';

class GameRoomCubit extends Cubit<GameRoomState> {
  final CreateRoomUseCase createRoomUseCase;
  final JoinRoomUseCase joinRoomUseCase;
  final LeaveRoomUseCase leaveRoomUseCase;
  final WatchRoomUseCase watchRoomUseCase;
  final PlayerReadyUseCase playerReadyUseCase;

  StreamSubscription<Either<Failure, RoomEntity?>>? _roomSubscription;

  GameRoomCubit({
    required this.createRoomUseCase,
    required this.joinRoomUseCase,
    required this.leaveRoomUseCase,
    required this.watchRoomUseCase,
    required this.playerReadyUseCase,
  }) : super(GameRoomInitial());

  void _watchRoom(String roomId) {
    _roomSubscription?.cancel();
    _roomSubscription = watchRoomUseCase
        .call(roomId)
        .listen(
          (result) {
        if (isClosed) return;

        result.fold(
              (failure) {
            emit(GameRoomError(failure.msg));
          },
              (room) {
            if (room == null) {
              emit(GameRoomClosed());
            } else {
              emit(GameRoomSuccess(room));
            }
          },
        );
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(GameRoomError(error.toString()));
        }
      },
    );
  }

  Future<void> createRoom() async {
    emit(GameRoomLoading());
    final result = await createRoomUseCase.call();
    result.fold((failure) => emit(GameRoomError(failure.msg)), (room) {
      emit(GameRoomSuccess(room));
      _watchRoom(room.roomId);
    });
  }

  Future<void> leaveRoom() async {
    final currentState = state;
    if (currentState is! GameRoomSuccess) {
      emit(GameRoomError('No active room to leave.'));
      return;
    }
    final roomId = currentState.room.roomId;
    emit(GameRoomLeaving());
    final result = await leaveRoomUseCase.call(roomId);
    result.fold((failure) => emit(GameRoomError(failure.msg)), (_) async {
      await _roomSubscription?.cancel();
      _roomSubscription = null;
      emit(GameRoomInitial());
    });
  }

  Future<void> joinRoom(String code) async{
    emit(GameRoomLoading());
    final result = await joinRoomUseCase.call(code);
    result.fold((failure) => emit(GameRoomError(failure.msg)), (room) {
      emit(GameRoomSuccess(room));
      _watchRoom(room.roomId);
    });

  }

  Future<void> PlayerReady(String userId , String roomId) async{
    final result = await playerReadyUseCase.call(userId, roomId);
    result.fold((failure) => emit(GameRoomError(failure.msg)), (_) => null);
  }

  @override
  Future<void> close() async{
    await _roomSubscription?.cancel();
    return super.close();
  }


}
