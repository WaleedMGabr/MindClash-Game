import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindclash/core/DI.dart';
import 'package:mindclash/features/authentication/presentations/cubits/auth_cubit.dart';
import 'package:mindclash/features/game/domain/entities/round_entity.dart';
import 'package:mindclash/features/game/presentations/cubits/game_cubit.dart';
import 'package:mindclash/features/game/presentations/cubits/game_state.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';
import 'package:mindclash/features/game_room/presentations/cubits/game_room_cubit.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is AuthSuccess ? authState.user.userId : '';

    return BlocBuilder<GameRoomCubit, GameRoomState>(
      builder: (context, roomState) {
        if (roomState is GameRoomClosed) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0E17),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.exit_to_app, color: Colors.orangeAccent, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'غادر الخصم المباراة وانتهى الجيم 🏆',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        context.read<GameRoomCubit>().leaveRoom();
                        Navigator.of(context).pushReplacementNamed('/mindclash');
                      },
                      child: const Text('العودة للرئيسية'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (roomState is! GameRoomSuccess) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final room = roomState.room;

        return BlocProvider<GameCubit>(
          create: (context) => sl<GameCubit>()
            ..initGame(
              roomId: room.roomId,
              currentUserId: currentUserId,
            ),
          child: _GameView(
            room: room,
            currentUserId: currentUserId,
          ),
        );
      },
    );
  }
}

class _GameView extends StatefulWidget {
  final RoomEntity room;
  final String currentUserId;

  const _GameView({
    required this.room,
    required this.currentUserId,
  });

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  final TextEditingController _trap1Controller = TextEditingController();
  final TextEditingController _trap2Controller = TextEditingController();
  int _lastRoundIndex = -1;
  RoundStatus? _lastRoundStatus;
  int _trapStep = 1; // 1: inputting trap 1, 2: inputting trap 2
  String _savedTrap1 = '';
  bool _hasSubmittedTraps = false;

  @override
  void dispose() {
    _trap1Controller.dispose();
    _trap2Controller.dispose();
    super.dispose();
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مغادرة المباراة'),
        content: const Text('هل أنت متأكد من رغبتك في الانسحاب من المباراة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GameRoomCubit>().leaveRoom();
              Navigator.of(context).pushReplacementNamed('/mindclash');
            },
            child: const Text('انسحاب'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmLeave(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0E17),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B1A2E),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Mind Clash',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                tooltip: 'مغادرة',
                onPressed: () => _confirmLeave(context),
              ),
            ],
          ),
        ),
        body: BlocConsumer<GameCubit, GameState>(
          listener: (context, state) {
            if (state is GameRoundState) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                setState(() {
                  _hasSubmittedTraps = false;
                });
              }
              final roundIndexChanged = state.round.roundIndex != _lastRoundIndex;
              final enteredSettingTrapper = _lastRoundStatus != RoundStatus.settingTrapper &&
                  state.round.roundStatus == RoundStatus.settingTrapper;

              _lastRoundStatus = state.round.roundStatus;
              if (roundIndexChanged) {
                _lastRoundIndex = state.round.roundIndex;
              }

              if (roundIndexChanged || enteredSettingTrapper) {
                setState(() {
                  _trapStep = 1;
                  _savedTrap1 = '';
                  _hasSubmittedTraps = false;
                  _trap1Controller.clear();
                  _trap2Controller.clear();
                });
              }
            }
          },
          builder: (context, state) {
            if (state is GameLoading || state is GameInitial) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.deepPurpleAccent),
                    SizedBox(height: 16),
                    Text(
                      'جاري تهيئة المعركة...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (state is GameOverState ||
                widget.room.roomStatus == RoomStatus.finished ||
                widget.room.players.length < 2) {
              return _buildGameOverView(context);
            }

            if (state is GameError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/mindclash'),
                        child: const Text('العودة للرئيسية'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is! GameRoundState) {
              return const SizedBox.shrink();
            }

            final round = state.round;
            final remaining = state.remainingSeconds;
            final maxDuration = round.roundStatus == RoundStatus.settingTrapper ? 60 : 30;

            return SafeArea(
              child: Column(
                children: [
                  _buildScoreBoard(context, round),
                  _buildTimerBar(remaining, maxDuration, round.roundStatus),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRoundHeaderBadge(round),
                          const SizedBox(height: 16),
                          _buildPhaseContent(context, state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScoreBoard(BuildContext context, RoundEntity round) {
    final players = widget.room.players.values.toList();
    final player1 = players.isNotEmpty ? players[0] : null;
    final player2 = players.length > 1 ? players[1] : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (player1 != null) _buildPlayerScoreCard(player1, round),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurpleAccent),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (player2 != null) _buildPlayerScoreCard(player2, round),
        ],
      ),
    );
  }

  Widget _buildPlayerScoreCard(dynamic player, RoundEntity round) {
    final isCurrent = player.playerId == widget.currentUserId;
    final isTrapper = player.playerId == round.trapperId;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isCurrent ? Colors.deepPurpleAccent : Colors.teal,
          child: Text(
            player.username.isNotEmpty ? player.username[0].toUpperCase() : 'P',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  player.username,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.white70,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isTrapper) ...[
                  const SizedBox(width: 4),
                  const Text('🪤', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
            Text(
              'نقاط: ${player.score}',
              style: const TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerBar(int remaining, int maxDuration, RoundStatus status) {
    final progress = maxDuration > 0 ? (remaining / maxDuration).clamp(0.0, 1.0) : 0.0;
    Color timerColor = Colors.greenAccent;
    if (remaining <= 5) {
      timerColor = Colors.redAccent;
    } else if (remaining <= 15) {
      timerColor = Colors.orangeAccent;
    }

    String phaseText = '';
    if (status == RoundStatus.settingTrapper) {
      phaseText = 'مرحلة زرع الفخاخ (60 ثانية)';
    } else if (status == RoundStatus.playerAnswer) {
      phaseText = 'مرحلة الإجابة (30 ثانية)';
    } else {
      phaseText = 'نتيجة الجولة';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                phaseText,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Row(
                children: [
                  Icon(Icons.timer, size: 14, color: timerColor),
                  const SizedBox(width: 4),
                  Text(
                    '$remaining ث',
                    style: TextStyle(
                      color: timerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(timerColor),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildRoundHeaderBadge(RoundEntity round) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF24223A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            'الجولة ${round.roundIndex + 1} من 10',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseContent(BuildContext context, GameRoundState state) {
    switch (state.round.roundStatus) {
      case RoundStatus.settingTrapper:
        return state.isTrapper
            ? _buildTrapperInputView(context, state)
            : _buildAnswererWaitingView(state);
      case RoundStatus.playerAnswer:
        return _buildAnsweringPhaseView(context, state);
      case RoundStatus.roundResult:
        return _buildRoundResultView(context, state);
    }
  }

  // Phase 1: Trapper Setting View (60 seconds) - Two-Step Trapper Flow
  Widget _buildTrapperInputView(BuildContext context, GameRoundState state) {
    final questionText = state.round.question.isNotEmpty
        ? state.round.question
        : (state.currentQuestion?.question ?? '');

    if (_hasSubmittedTraps) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Card
          Card(
            color: const Color(0xFF1E1D36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'أنت زارع الفخاخ 🪤',
                      style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    questionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1D36),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 56),
                SizedBox(height: 16),
                Text(
                  'تم زرع الفخاخ بنجاح! 🪤',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'في انتظار بدء مرحلة الإجابة للخصم...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Card
        Card(
          color: const Color(0xFF1E1D36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'أنت زارع الفخاخ 🪤',
                        style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _trapStep == 1
                            ? Colors.purple.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _trapStep == 1 ? 'المرحلة 1 من 2' : 'المرحلة 2 من 2',
                        style: TextStyle(
                          color: _trapStep == 1 ? Colors.purpleAccent : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Step 1: Inputting Trap 1
        if (_trapStep == 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'المرحلة الأولى: اكتب إجابة مضللة رقم 1.\nبعد التأكيد سيتم قفل الفخ الأول ولن تتمكن من رؤيته!',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _trap1Controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'الفخ الأول 🪤',
              labelStyle: const TextStyle(color: Colors.purpleAccent),
              hintText: 'اكتب إجابة مضللة رقم 1...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E1D36),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purpleAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            onPressed: () {
              final t1 = _trap1Controller.text.trim();
              if (t1.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى كتابة الفخ الأول أولاً!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              final correct = (state.currentQuestion?.correctAnswer ?? '').trim().toLowerCase();
              if (correct.isNotEmpty && t1.toLowerCase() == correct) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لقد كتبت الإجابة الصحيحة! الفخ يجب أن يكون إجابة مضللة'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              setState(() {
                _savedTrap1 = t1;
                _trap1Controller.clear();
                _trapStep = 2;
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'تأكيد وقفل الفخ الأول 🔒',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],

        // Step 2: Inputting Trap 2 (Trap 1 is completely hidden and cannot be seen)
        if (_trapStep == 2) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم حفظ وقفل الفخ الأول بنجاح! 🔒\nاكتب الآن الفخ الثاني (ممنوع كتابة نفس إجابة الفخ الأول أو الإجابة الصحيحة).',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _trap2Controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'الفخ الثاني 🪤',
              labelStyle: const TextStyle(color: Colors.purpleAccent),
              hintText: 'اكتب إجابة مضللة رقم 2...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E1D36),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.purpleAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            onPressed: state.isSubmitting
                ? null
                : () {
                    final t2 = _trap2Controller.text.trim();
                    if (t2.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى كتابة الفخ الثاني أولاً!'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    if (t2.toLowerCase() == _savedTrap1.toLowerCase()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ممنوع كتابة نفس إجابة الفخ الأول! اكتب فخاً مختلفاً'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    final correct = (state.currentQuestion?.correctAnswer ?? '').trim().toLowerCase();
                    if (correct.isNotEmpty && t2.toLowerCase() == correct) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('لقد كتبت الإجابة الصحيحة! الفخ يجب أن يكون إجابة مضللة'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _hasSubmittedTraps = true;
                    });
                    context.read<GameCubit>().submitTraps(
                          _savedTrap1,
                          t2,
                        );
                  },
            child: state.isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.radar, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'زر زرع الفخاخ 🪤',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }

  // Phase 1: Answerer Waiting View (Trapper is setting traps)
  Widget _buildAnswererWaitingView(GameRoundState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withOpacity(0.15),
                border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4), width: 2),
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 64,
                color: Colors.amberAccent,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'الخصم يزرع الفخاخ... 🪤',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'استعد لتفادي الأجوبة الخادعة واختيار الحقيقة!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'الوقت المتبقي لخصمك: ${state.remainingSeconds} ث',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phase 2: Answering Phase View (30 seconds, 4 choices or 2 choices fallback)
  Widget _buildAnsweringPhaseView(BuildContext context, GameRoundState state) {
    final round = state.round;
    final isAnswerer = state.isAnswerer;
    final isTimeout = round.isTrapperTimedOut;
    final questionText = round.question.isNotEmpty
        ? round.question
        : (state.currentQuestion?.question ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Timeout Warning Banner if Trapper took too long
        if (isTimeout)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: const Row(
              children: [
                Icon(Icons.alarm_off, color: Colors.orangeAccent, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⏰ الخصم لم يزرع فخاخاً في الوقت المحدد! أمامك خياران فقط.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Question Card
        Card(
          color: const Color(0xFF1E1D36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAnswerer ? Colors.blue.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAnswerer ? 'دورك للإجابة 🎯' : 'الخصم يختار الآن 👀',
                        style: TextStyle(
                          color: isAnswerer ? Colors.lightBlueAccent : Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isTimeout)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '2 خيارات فقط',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Choices List
        if (round.currentChoices.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ...round.currentChoices.map((choiceMap) {
            final choiceText = choiceMap.keys.first;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: isAnswerer
                  ? _buildAnswerChoiceButton(context, choiceText, state.isSubmitting)
                  : _buildSpectatorChoiceCard(choiceText),
            );
          }),

        if (!isAnswerer) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_red_eye_outlined, color: Colors.white60, size: 18),
                SizedBox(width: 8),
                Text(
                  'أنت تشاهد الآن... هل سيقع خصمك في فخك؟',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnswerChoiceButton(BuildContext context, String text, bool isSubmitting) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF24223A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.white12),
        ),
        elevation: 2,
      ),
      onPressed: isSubmitting
          ? null
          : () {
              context.read<GameCubit>().submitAnswer(text);
            },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.circle_outlined, size: 14, color: Colors.deepPurpleAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectatorChoiceCard(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1D36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked, color: Colors.white30, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // Phase 3: Round Result Reveal View (4 seconds)
  Widget _buildRoundResultView(BuildContext context, GameRoundState state) {
    final round = state.round;
    final isAnswerer = state.isAnswerer;
    final chosenAnswer = round.playerAnswer;
    final awardedTo = round.awardedTo;

    String resultTitle = '';
    Color resultColor = Colors.white;
    IconData resultIcon = Icons.info_outline;

    if (awardedTo == 'answerer') {
      resultTitle = isAnswerer
          ? '🎉 إجابة صحيحة! حصلت على نقطة!'
          : 'خصمك اختار الإجابة الصحيحة!';
      resultColor = Colors.greenAccent;
      resultIcon = Icons.check_circle;
    } else if (awardedTo == 'trapper') {
      resultTitle = isAnswerer
          ? '🪤 لقد وقعت في الفخ! نقطة للخصم!'
          : '🎉 رائع! وقع خصمك في فخك ونلت نقطة!';
      resultColor = Colors.purpleAccent;
      resultIcon = Icons.warning_amber_rounded;
    } else {
      resultTitle = '❌ إجابة خاطئة! لم يحصل أحد على نقاط.';
      resultColor = Colors.orangeAccent;
      resultIcon = Icons.cancel;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Result Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: resultColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: resultColor.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Icon(resultIcon, color: resultColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  resultTitle,
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'كشف الأجوبة:',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Display reveal for each choice
        ...round.currentChoices.map((choiceMap) {
          final choiceText = choiceMap.keys.first;
          final type = choiceMap.values.first;
          final wasChosen = choiceText == chosenAnswer;

          Color cardBg = const Color(0xFF1E1D36);
          Color borderColor = Colors.white12;
          Widget badge;

          if (type == Trapper.correct) {
            cardBg = Colors.green.withOpacity(0.2);
            borderColor = Colors.greenAccent;
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('صحيحة ✅', style: TextStyle(color: Colors.white, fontSize: 11)),
            );
          } else if (type == Trapper.rival) {
            cardBg = Colors.purple.withOpacity(0.2);
            borderColor = Colors.purpleAccent;
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('فخ 🪤', style: TextStyle(color: Colors.white, fontSize: 11)),
            );
          } else {
            cardBg = Colors.black26;
            borderColor = Colors.white24;
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('نظامي ❌', style: TextStyle(color: Colors.white70, fontSize: 11)),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: wasChosen ? 2 : 1),
            ),
            child: Row(
              children: [
                if (wasChosen) ...[
                  const Icon(Icons.arrow_right_alt, color: Colors.amberAccent, size: 24),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    choiceText,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: wasChosen ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                badge,
              ],
            ),
          );
        }),
      ],
    );
  }

  // Game Over View / Podium
  Widget _buildGameOverView(BuildContext context) {
    final players = widget.room.players.values.toList();
    players.sort((a, b) => b.score.compareTo(a.score));

    final opponentLeft = players.length < 2;
    final isDraw = !opponentLeft && players.length >= 2 && players[0].score == players[1].score;
    final winner = players.isNotEmpty ? players[0] : null;

    final title = opponentLeft ? 'انتهت المباراة بالانسحاب!' : 'انتهت المعركة!';
    final subtitle = opponentLeft
        ? 'انقطع اتصال الخصم أو غادر المباراة! 🏆 فزت بالمباراة!'
        : (isDraw
            ? 'تعادل مشوق بين اللاعبين! 🤝'
            : 'الفائز: ${winner?.username ?? ''} 👑');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),

            // Scores Card
            Card(
              color: const Color(0xFF1E1D36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: players.map((player) {
                    final isTop = !isDraw && player == winner;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (isTop)
                                const Text('👑 ', style: TextStyle(fontSize: 18))
                              else
                                const SizedBox(width: 8),
                              Text(
                                player.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTop ? Colors.amber.withOpacity(0.2) : Colors.white10,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${player.score} نقطة',
                              style: TextStyle(
                                color: isTop ? Colors.amberAccent : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<GameRoomCubit>().leaveRoom();
                Navigator.of(context).pushReplacementNamed('/mindclash');
              },
              child: const Text(
                'العودة للقائمة الرئيسية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}