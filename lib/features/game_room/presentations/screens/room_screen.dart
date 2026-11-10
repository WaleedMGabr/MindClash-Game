import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindclash/core/theme/app_colors.dart';
import 'package:mindclash/core/theme/app_decorations.dart';
import 'package:mindclash/core/theme/app_text_styles.dart';
import 'package:mindclash/features/authentication/presentations/cubits/auth_cubit.dart';
import 'package:mindclash/features/game_room/domain/entities/player_entity.dart';
import 'package:mindclash/features/game_room/domain/entities/room_entity.dart';
import 'package:mindclash/features/game_room/presentations/cubits/game_room_cubit.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.elevatedSlate,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('مغادرة الغرفة', style: AppTextStyles.h2()),
        content: Text('هل أنت متأكد من رغبتك في مغادرة غرفة الانتظار؟', style: AppTextStyles.body()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('إلغاء', style: AppTextStyles.body(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyberCrimson,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<GameRoomCubit>().leaveRoom();
              Navigator.of(context).pushReplacementNamed('/mindclash');
            },
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is AuthSuccess ? authState.user.userId : '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmLeave(context);
      },
      child: BlocConsumer<GameRoomCubit, GameRoomState>(
        listener: (context, state) {
          if (state is GameRoomSuccess) {
            if (state.room.roomStatus == RoomStatus.playing) {
              if (ModalRoute.of(context)?.isCurrent == true) {
                Navigator.of(context).pushReplacementNamed('/game');
              }
            }
          } else if (state is GameRoomClosed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إغلاق الغرفة من قبل المضيف.'),
                backgroundColor: AppColors.voltAmber,
              ),
            );
            if (ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).pop();
            }
          } else if (state is GameRoomInitial) {
            if (ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).pop();
            }
          } else if (state is GameRoomError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.msg),
                backgroundColor: AppColors.cyberCrimson,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GameRoomLeaving) {
            return Scaffold(
              backgroundColor: AppColors.voidCanvas,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.cyberCrimson),
                    const SizedBox(height: 16),
                    Text('جاري مغادرة الغرفة...', style: AppTextStyles.h2()),
                  ],
                ),
              ),
            );
          }

          if (state is! GameRoomSuccess) {
            return Scaffold(
              backgroundColor: AppColors.voidCanvas,
              appBar: AppBar(
                backgroundColor: AppColors.elevatedSlate,
                title: Text('غرفة الانتظار', style: AppTextStyles.h2()),
              ),
              body: const Center(
                child: CircularProgressIndicator(color: AppColors.electricViolet),
              ),
            );
          }

          final room = state.room;
          final playersList = room.players.values.toList();
          final isFull = room.players.length >= 2;
          final myPlayer = room.players[currentUserId];
          final isMeReady = myPlayer?.isReady ?? false;
          final isGameReady = isFull && playersList.every((p) => p.isReady);

          PlayerEntity? hostPlayer;
          PlayerEntity? guestPlayer;
          for (final p in playersList) {
            if (p.playerId == room.hostId) {
              hostPlayer = p;
            } else {
              guestPlayer = p;
            }
          }
          hostPlayer ??= playersList.isNotEmpty ? playersList.first : null;
          final hasGuest = guestPlayer != null;

          return Scaffold(
            backgroundColor: AppColors.voidCanvas,
            appBar: AppBar(
              backgroundColor: AppColors.elevatedSlate,
              elevation: 0,
              title: Text('غرفة المعركة', style: AppTextStyles.h2()),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                onPressed: () => _confirmLeave(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Room Code Hero Card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                    decoration: AppDecorations.glassCard(),
                    child: Column(
                      children: [
                        Text(
                          'كود الغرفة الخاص (Room Code)',
                          style: AppTextStyles.bodySmall(color: AppColors.neonLavender),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          room.code,
                          style: AppTextStyles.digitalCode(color: AppColors.solarCore, fontSize: 34),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.elevatedSlate,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: AppColors.borderFrost),
                            ),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: room.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ كود الغرفة إلى الحافظة! 📋'),
                                backgroundColor: AppColors.hyperEmerald,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('نسخ الكود'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Room Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isFull
                          ? AppColors.hyperEmerald.withOpacity(0.12)
                          : AppColors.voltAmber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFull ? AppColors.hyperEmerald : AppColors.voltAmber,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isFull ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                          color: isFull ? AppColors.hyperEmerald : AppColors.voltAmber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFull
                              ? 'اكتملت الغرفة (2/2)! اضغط جاهز لبدء المعركة'
                              : 'في انتظار انضمام الخصم (1/2)...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isFull ? AppColors.hyperEmerald : AppColors.voltAmber,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // The 1v1 Faceoff Duel Arena
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppDecorations.glassCard(),
                    child: Column(
                      children: [
                        Text('المتنافسان ⚔️', style: AppTextStyles.h1().copyWith(fontSize: 20)),
                        const SizedBox(height: 20),

                        // Host Player Card
                        if (hostPlayer != null)
                          _buildPlayerCard(
                            context: context,
                            player: hostPlayer,
                            isHost: true,
                            isMe: hostPlayer.playerId == currentUserId,
                          ),
                        const SizedBox(height: 14),

                        // VS Energy Divider
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.electricViolet.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.electricViolet.withOpacity(0.4)),
                          ),
                          child: Text(
                            'VS',
                            style: AppTextStyles.hero(color: AppColors.solarCore).copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Guest Player Card or Waiting Slot
                        if (hasGuest && guestPlayer != null)
                          _buildPlayerCard(
                            context: context,
                            player: guestPlayer,
                            isHost: false,
                            isMe: guestPlayer.playerId == currentUserId,
                          )
                        else
                          _buildWaitingSlot(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Ready Action Button
                  if (isGameReady) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppDecorations.neonCard(glowColor: AppColors.hyperEmerald),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: AppColors.hyperEmerald, strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'كلا اللاعبين جاهز! جاري إطلاق المعركة...',
                            style: AppTextStyles.button(color: AppColors.hyperEmerald),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMeReady ? AppColors.hyperEmerald : AppColors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        shadowColor: (isMeReady ? AppColors.hyperEmerald : AppColors.electricViolet).withOpacity(0.5),
                      ),
                      onPressed: isMeReady
                          ? null
                          : () {
                              context.read<GameRoomCubit>().PlayerReady(
                                    currentUserId,
                                    room.roomId,
                                  );
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isMeReady ? Icons.check_circle_rounded : Icons.flash_on, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isMeReady ? 'أنت مستعد وجاهز! ✅' : 'أنا مستعد للمعركة ⚡',
                            style: AppTextStyles.button(fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard({
    required BuildContext context,
    required PlayerEntity player,
    required bool isHost,
    required bool isMe,
  }) {
    final isReady = player.isReady == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.elevatedSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReady ? AppColors.hyperEmerald.withOpacity(0.6) : AppColors.borderSubtle,
          width: isReady ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isHost ? AppColors.electricViolet : AppColors.mintCyan,
            child: Text(
              player.username.isNotEmpty ? player.username[0].toUpperCase() : 'P',
              style: AppTextStyles.button(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(player.username, style: AppTextStyles.h2()),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.electricViolet.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('أنت', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ],
                  ],
                ),
                Text(
                  isHost ? 'المضيف 👑' : 'المنافس ⚡',
                  style: AppTextStyles.bodySmall(color: isHost ? AppColors.solarCore : AppColors.mintCyan),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isReady
                  ? AppColors.hyperEmerald.withOpacity(0.18)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isReady ? AppColors.hyperEmerald : Colors.white24,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isReady ? Icons.check_circle_rounded : Icons.pending_rounded,
                  color: isReady ? AppColors.hyperEmerald : Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isReady ? 'مستعد ✅' : 'ينتظر...',
                  style: TextStyle(
                    color: isReady ? AppColors.hyperEmerald : Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingSlot() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.voidCanvas.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person_add_rounded, color: Colors.white38, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('في انتظار انضمام الخصم...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                Text('شارك الكود مع صديقك', style: TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.voltAmber),
          ),
        ],
      ),
    );
  }
}