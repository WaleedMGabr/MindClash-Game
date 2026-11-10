import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get_it/get_it.dart';
import 'package:mindclash/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:mindclash/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:mindclash/features/authentication/domain/repositories/auth_repository.dart';
import 'package:mindclash/features/authentication/domain/use_cases/auth_usecases.dart';
import 'package:mindclash/features/authentication/presentations/cubits/auth_cubit.dart';
import 'package:mindclash/features/game/data/datasources/game_remote_datasource.dart';
import 'package:mindclash/features/game/data/repositories/game_repository_impl.dart';
import 'package:mindclash/features/game/domain/repositories/game_repository.dart';
import 'package:mindclash/features/game/domain/use_cases/game_usecases.dart';
import 'package:mindclash/features/game/presentations/cubits/game_cubit.dart';
import 'package:mindclash/features/game_room/data/datasources/game_room_remote_datasource.dart';
import 'package:mindclash/features/game_room/data/repositories/game_room_repository_impl.dart';
import 'package:mindclash/features/game_room/domain/repositories/game_room_repository.dart';
import 'package:mindclash/features/game_room/domain/use_cases/game_room_usecases.dart';
import 'package:mindclash/features/game_room/presentations/cubits/game_room_cubit.dart';

final sl = GetIt.instance;

void setupLocator() {
  /// External (Firebase)
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseDatabase>(
    () => FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://mind-clash-1756b-default-rtdb.firebaseio.com',
    ),
  );

  /// DataSources
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<GameRemoteDatasource>(
    () => GameRemoteDatasourceImpl(
      firebaseFirestore: sl<FirebaseFirestore>(),
      firebaseDatabase: sl<FirebaseDatabase>(),
    ),
  );
  sl.registerLazySingleton<GameRoomRemoteDatasource>(
    () => GameRoomRemoteDatasourceImpl(
      sl<FirebaseDatabase>(),
      sl<AuthRemoteDatasource>(),
      gameRemoteDatasource: sl<GameRemoteDatasource>(),
    ),
  );

  /// Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthRemoteDatasource>()),
  );
  sl.registerLazySingleton<GameRoomRepository>(
    () => GameRoomRepositoryImpl(sl<GameRoomRemoteDatasource>()),
  );
  sl.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(gameRemoteDatasource: sl<GameRemoteDatasource>()),
  );

  /// Use cases - Auth
  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<SignupUseCase>(
    () => SignupUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(sl<AuthRepository>()),
  );

  /// Use cases - Game Room
  sl.registerLazySingleton<CreateRoomUseCase>(
    () => CreateRoomUseCase(sl<GameRoomRepository>()),
  );
  sl.registerLazySingleton<JoinRoomUseCase>(
    () => JoinRoomUseCase(sl<GameRoomRepository>()),
  );
  sl.registerLazySingleton<LeaveRoomUseCase>(
    () => LeaveRoomUseCase(sl<GameRoomRepository>()),
  );
  sl.registerLazySingleton<WatchRoomUseCase>(
    () => WatchRoomUseCase(sl<GameRoomRepository>()),
  );
  sl.registerLazySingleton<PlayerReadyUseCase>(
    () => PlayerReadyUseCase(sl<GameRoomRepository>()),
  );

  /// Use cases - Game
  sl.registerLazySingleton<LoadAndLockQuestionsUseCase>(
    () => LoadAndLockQuestionsUseCase(sl<GameRepository>()),
  );
  sl.registerLazySingleton<GetRoomQuestionsUseCase>(
    () => GetRoomQuestionsUseCase(sl<GameRepository>()),
  );
  sl.registerLazySingleton<WatchCurrentRoundUseCase>(
    () => WatchCurrentRoundUseCase(sl<GameRepository>()),
  );
  sl.registerLazySingleton<SubmitTrapsUseCase>(
    () => SubmitTrapsUseCase(sl<GameRepository>()),
  );
  sl.registerLazySingleton<HandleTrapperTimeoutUseCase>(
    () => HandleTrapperTimeoutUseCase(sl<GameRepository>()),
  );
  sl.registerLazySingleton<SubmitUserAnswerUseCase>(
    () => SubmitUserAnswerUseCase(sl<GameRepository>()),
  );
  sl.registerLazySingleton<NextRoundUseCase>(
    () => NextRoundUseCase(sl<GameRepository>()),
  );

  /// Cubits
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      loginUseCase: sl<LoginUseCase>(),
      signupUseCase: sl<SignupUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
    ),
  );

  sl.registerFactory<GameRoomCubit>(
    () => GameRoomCubit(
      createRoomUseCase: sl<CreateRoomUseCase>(),
      joinRoomUseCase: sl<JoinRoomUseCase>(),
      leaveRoomUseCase: sl<LeaveRoomUseCase>(),
      watchRoomUseCase: sl<WatchRoomUseCase>(),
      playerReadyUseCase: sl<PlayerReadyUseCase>(),
    ),
  );

  sl.registerFactory<GameCubit>(
    () => GameCubit(
      watchCurrentRoundUseCase: sl<WatchCurrentRoundUseCase>(),
      getRoomQuestionsUseCase: sl<GetRoomQuestionsUseCase>(),
      submitTrapsUseCase: sl<SubmitTrapsUseCase>(),
      handleTrapperTimeoutUseCase: sl<HandleTrapperTimeoutUseCase>(),
      submitUserAnswerUseCase: sl<SubmitUserAnswerUseCase>(),
      nextRoundUseCase: sl<NextRoundUseCase>(),
    ),
  );
}

