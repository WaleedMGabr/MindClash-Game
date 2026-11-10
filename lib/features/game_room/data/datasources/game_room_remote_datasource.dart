import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:mindclash/core/errors/exceptions.dart';
import 'package:mindclash/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:mindclash/features/game/data/datasources/game_remote_datasource.dart';
import 'package:mindclash/features/game/data/models/question_model.dart';
import 'package:mindclash/features/game/data/models/round_model.dart';
import 'package:mindclash/features/game/domain/entities/round_entity.dart';
import 'package:mindclash/features/game_room/data/models/player_model.dart';
import 'package:mindclash/features/game_room/data/models/room_model.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';

abstract class GameRoomRemoteDatasource {
  Future<RoomModel> createRoom();
  Future<RoomModel> joinRoom(String code);
  Future<void> leaveRoom(String roomId);
  Stream<RoomModel?> watchRoom(String roomId);
  Future<void> PlayerReady(String userId , String roomId);
}

class GameRoomRemoteDatasourceImpl implements GameRoomRemoteDatasource {
  final FirebaseDatabase firebaseDatabase;
  final AuthRemoteDatasource authRemoteDatasource;
  final GameRemoteDatasource? gameRemoteDatasource;

  GameRoomRemoteDatasourceImpl(
    this.firebaseDatabase,
    this.authRemoteDatasource, {
    this.gameRemoteDatasource,
  });

  Future<void> _ensureUserNotInRoom(String uid) async {
    final userRoomRef = firebaseDatabase.ref('userRooms/$uid');
    final snapshot = await userRoomRef.get();
    if (!snapshot.exists || snapshot.value == null) return; // User is free

    final existingRoomId = snapshot.value.toString();
    try {
      await leaveRoom(existingRoomId);
    } catch (_) {
      // If leaveRoom failed (e.g. room already destroyed), clean up stale entry
      await userRoomRef.remove();
    }
  }

  Future<void> _cleanupEmptyRooms() async {
    try {
      final snapshot = await firebaseDatabase.ref('rooms').get();
      if (!snapshot.exists || snapshot.value is! Map) return;

      final allRooms = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final updates = <String, dynamic>{};

      for (final entry in allRooms.entries) {
        final rId = entry.key.toString();
        final rData = entry.value;
        if (rData is Map) {
          final players = rData['players'];
          final code = rData['code']?.toString() ?? '';
          final hasNoPlayers = players == null || (players is Map && players.isEmpty);

          if (hasNoPlayers) {
            updates['rooms/$rId'] = null;
            if (code.isNotEmpty) {
              updates['roomCodes/$code'] = null;
            }
          }
        }
      }

      if (updates.isNotEmpty) {
        await firebaseDatabase.ref().update(updates);
      }
    } catch (_) {
      // Best-effort cleanup, don't block room creation if cleanup fails
    }
  }

  @override
  Future<RoomModel> createRoom() async {
    try {
      final host = authRemoteDatasource.getCurrentUser();
      if (host == null) {
        throw const ServerException('User must be logged in to create a room');
      }
      await _cleanupEmptyRooms();
      await _ensureUserNotInRoom(host.userId);

      final DatabaseReference roomRef = firebaseDatabase.ref("rooms").push();
      final roomId = roomRef.key;

      if (roomId == null) {
        throw const ServerException('Failed to generate room reference key');
      }

      // Generate a strictly 8-digit random room code (10000000 - 99999999)
      var roomCode = (10000000 + Random().nextInt(90000000)).toString();

      DatabaseReference roomCodesRef = firebaseDatabase.ref("roomCodes/$roomCode");
      DataSnapshot snapshot = await roomCodesRef.get();
      while (snapshot.exists) {
        roomCode = (10000000 + Random().nextInt(90000000)).toString();
        roomCodesRef = firebaseDatabase.ref("roomCodes/$roomCode");
        snapshot = await roomCodesRef.get();
      }

      final hostPlayer = PlayerModel(
        playerId: host.userId,
        username: host.username,
        score: 0,
      );

      final room = RoomModel(
        roomId: roomId,
        code: roomCode,
        hostId: host.userId,
        roomStatus: RoomStatus.waiting,
        players: {host.userId: hostPlayer},
        currentQuestionIndex: 0,
      );

      await roomRef.set(room.toMap());
      await roomCodesRef.set(roomId);
      await firebaseDatabase.ref('userRooms/${host.userId}').set(roomId);

      // Set onDisconnect handlers for automatic cleanup
      await firebaseDatabase
          .ref('rooms/$roomId/players/${host.userId}')
          .onDisconnect()
          .remove();
      await firebaseDatabase
          .ref('userRooms/${host.userId}')
          .onDisconnect()
          .remove();

      return room;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RoomModel> joinRoom(String code) async {
    try {
      final user = authRemoteDatasource.getCurrentUser();
      if (user == null) {
        throw const ServerException('User must be logged in to join a room');
      }
      await _ensureUserNotInRoom(user.userId);

      final DatabaseReference roomCodesRef = firebaseDatabase.ref("roomCodes/$code");
      final snapshot = await roomCodesRef.get();
      if (!snapshot.exists || snapshot.value == null) {
        throw const ServerException('Room not found');
      }

      final codeValue = snapshot.value;
      final String? roomId;
      if (codeValue is String) {
        roomId = codeValue;
      } else if (codeValue is Map) {
        roomId = (codeValue[code] ?? (codeValue.values.isNotEmpty ? codeValue.values.first : null))?.toString();
      } else {
        roomId = codeValue.toString();
      }

      if (roomId == null || roomId.isEmpty) {
        throw const ServerException('Invalid room code');
      }

      final roomRef = firebaseDatabase.ref("rooms/$roomId");
      final roomSnapshot = await roomRef.get();
      if (!roomSnapshot.exists || roomSnapshot.value == null) {
        throw const ServerException('Room does not exist');
      }

      final roomMap = Map<dynamic, dynamic>.from(roomSnapshot.value as Map);
      final status = roomMap['roomStatus'] as String?;
      if (status != RoomStatus.waiting.name) {
        throw const ServerException('Room is already in progress or closed');
      }

      final playersRaw = roomMap['players'];
      final players = playersRaw is Map ? Map<dynamic, dynamic>.from(playersRaw) : {};
      if (!players.containsKey(user.userId) && players.length >= 2) {
        throw const ServerException('Room is full');
      }

      final player = PlayerModel(
        playerId: user.userId,
        username: user.username,
        score: 0,
      );

      // Add the player to the room
      await firebaseDatabase
          .ref('rooms/$roomId/players/${user.userId}')
          .set(player.toMap());

      await firebaseDatabase.ref('userRooms/${user.userId}').set(roomId);

      // Set onDisconnect handlers for automatic cleanup
      await firebaseDatabase
          .ref('rooms/$roomId/players/${user.userId}')
          .onDisconnect()
          .remove();
      await firebaseDatabase
          .ref('userRooms/${user.userId}')
          .onDisconnect()
          .remove();

      // Read updated room data
      final updatedRoomSnapshot = await roomRef.get();
      return RoomModel.fromMap(
        Map<dynamic, dynamic>.from(updatedRoomSnapshot.value as Map),
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    try {
      final user = authRemoteDatasource.getCurrentUser();
      if (user == null) {
        throw const ServerException('User must be logged in to leave a room');
      }
      // Step 1: Cancel onDisconnect handlers (we're leaving intentionally)
      await firebaseDatabase
          .ref('rooms/$roomId/players/${user.userId}')
          .onDisconnect()
          .cancel();
      await firebaseDatabase
          .ref('userRooms/${user.userId}')
          .onDisconnect()
          .cancel();

      // Step 2: Read the full room to determine role and get room code
      final roomRef = firebaseDatabase.ref('rooms/$roomId');
      final roomSnapshot = await roomRef.get();
      if (!roomSnapshot.exists || roomSnapshot.value == null) {
        // Room already gone (e.g. host left first) — just clean up our userRooms
        await firebaseDatabase.ref('userRooms/${user.userId}').remove();
        return;
      }
      final room = RoomModel.fromMap(
        Map<dynamic, dynamic>.from(roomSnapshot.value as Map),
      );

      // Verify if user is actually in this room
      if (!room.players.containsKey(user.userId)) {
        await firebaseDatabase.ref('userRooms/${user.userId}').remove();
        return;
      }

      if (room.roomStatus == RoomStatus.playing) {
        // MATCH IN PROGRESS: Mark game as finished due to abandonment
        final updates = <String, dynamic>{
          'rooms/$roomId/players/${user.userId}': null,
          'userRooms/${user.userId}': null,
          'rooms/$roomId/roomStatus': RoomStatus.finished.name,
          'rooms/$roomId/abandonedBy': user.userId,
        };
        await firebaseDatabase.ref().update(updates);
        return;
      }

      final isHost = room.hostId == user.userId;
      if (isHost) {
        // HOST LEAVING: Destroy the entire room atomically
        final updates = <String, dynamic>{
          'rooms/$roomId': null,
          'roomCodes/${room.code}': null,
        };
        for (final uid in room.players.keys) {
          updates['userRooms/$uid'] = null;
        }
        // Cancel onDisconnect for other players too (best-effort)
        for (final uid in room.players.keys) {
          if (uid != user.userId) {
            await firebaseDatabase
                .ref('rooms/$roomId/players/$uid')
                .onDisconnect()
                .cancel();
            await firebaseDatabase
                .ref('userRooms/$uid')
                .onDisconnect()
                .cancel();
          }
        }
        await firebaseDatabase.ref().update(updates);
      } else {
        // GUEST LEAVING: Remove self from the room
        final updates = <String, dynamic>{
          'rooms/$roomId/players/${user.userId}': null,
          'userRooms/${user.userId}': null,
        };
        await firebaseDatabase.ref().update(updates);
        // Check if room is now empty → clean up room + code
        final updatedSnapshot = await roomRef.get();
        if (updatedSnapshot.exists && updatedSnapshot.value != null) {
          final updatedRoom = RoomModel.fromMap(
            Map<dynamic, dynamic>.from(updatedSnapshot.value as Map),
          );
          if (updatedRoom.players.isEmpty) {
            await firebaseDatabase.ref().update({
              'rooms/$roomId': null,
              'roomCodes/${room.code}': null,
            });
          }
        }
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<RoomModel?> watchRoom(String roomId) {
    return firebaseDatabase.ref('rooms/$roomId').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) {
        return null;
      }
      final room = RoomModel.fromMap(
        Map<dynamic, dynamic>.from(value),
      );

      // // Cancel onDisconnect deletion if the match is in playing state
      // if (room.roomStatus == RoomStatus.playing) {
      //   final currentUser = authRemoteDatasource.getCurrentUser();
      //   if (currentUser != null) {
      //     firebaseDatabase
      //         .ref('rooms/$roomId/players/${currentUser.userId}')
      //         .onDisconnect()
      //         .cancel();
      //     firebaseDatabase
      //         .ref('userRooms/${currentUser.userId}')
      //         .onDisconnect()
      //         .cancel();
      //   }
      // }

      return room;
    });
  }

  @override
  Future<void> PlayerReady(String userId, String roomId) async{
    try{
      final DatabaseReference userRoomRef = firebaseDatabase.ref('rooms/$roomId/players/$userId');
      //condition
      DataSnapshot snapshot = await userRoomRef.get();
      if(!snapshot.exists){
        throw const ServerException('User not in room');
      }
      await userRoomRef.update({
        'isReady': true,
      });

      ///check if room full (2 Players) + ready => change state of room to Playing
      final roomRef = firebaseDatabase.ref('rooms/$roomId');
      final roomSnapshot = await roomRef.get();
      if (roomSnapshot.exists && roomSnapshot.value is Map) {
        final roomMap = Map<dynamic, dynamic>.from(roomSnapshot.value as Map);
        final rawPlayers = roomMap['players'];
        if (rawPlayers is Map) {
          final players = Map<dynamic, dynamic>.from(rawPlayers);
          final allReady = players.length >= 2 &&
              players.values.every((p) => p is Map && p['isReady'] == true);
          if (allReady) {
            // 1. Fetch 10 questions with 10-day cooldown
            List<QuestionModel> questions = [];
            if (gameRemoteDatasource != null) {
              try {
                questions = await gameRemoteDatasource!.loadAndLockQuestions();
              } catch (_) {
                // Questions will be loaded if available in Firestore
              }
            }

            final hostId = roomMap['hostId']?.toString() ?? '';
            final guestId = players.keys.firstWhere(
              (k) => k != hostId,
              orElse: () => '',
            );

            // 60 seconds for Trap Setting phase in Round 0
            final deadline = DateTime.now().add(const Duration(seconds: 60)).millisecondsSinceEpoch;

            final round0 = RoundModel(
              roundIndex: 0,
              question: questions.isNotEmpty ? questions[0].question : '',
              trapperId: hostId,
              answererId: guestId,
              roundStatus: RoundStatus.settingTrapper,
              currentChoices: const [],
              playerAnswer: '',
              correctAnswer: questions.isNotEmpty ? questions[0].correctAnswer : '',
              phaseDeadline: deadline,
              awardedTo: null,
              isTrapperTimedOut: false,
            );

            await roomRef.update({
              'roomStatus': RoomStatus.playing.name,
              'currentQuestionIndex': 0,
              'questions': questions.map((q) => q.toMap()).toList(),
              'currentRound': round0.toMap(),
            });
          }
        }
      }

    }catch(e){
      if(e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}