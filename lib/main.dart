import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindclash/core/DI.dart';
import 'package:mindclash/features/authentication/presentations/cubits/auth_cubit.dart';
import 'package:mindclash/features/authentication/presentations/screens/login_screen.dart';
import 'package:mindclash/features/authentication/presentations/screens/signup_screen.dart';
import 'package:mindclash/features/game/presentations/screens/game_screen.dart';
import 'package:mindclash/features/game_room/presentations/screens/mindClash_screen.dart';
import 'package:mindclash/features/game_room/presentations/screens/room_screen.dart';
import 'package:mindclash/features/home/presentation/screens/home_screen.dart';
import 'package:mindclash/core/theme/app_colors.dart';
import 'package:mindclash/features/splash/presentation/screens/splash_screen.dart';
import 'package:mindclash/firebase_options.dart';

import 'features/game_room/presentations/cubits/game_room_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase already initialized or initialization error: $e');
  }

  setupLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (context) => sl<GameRoomCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MindClash',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.voidCanvas,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.electricViolet,
            secondary: AppColors.hyperEmerald,
            surface: AppColors.obsidianGlass,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/room': (context) => const RoomScreen(),
          '/mindclash': (context) => const MindclashScreen(),
          '/game': (context) => const GameScreen(),
        },
      ),
    );
  }
}