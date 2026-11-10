import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindclash/core/theme/app_colors.dart';
import 'package:mindclash/core/theme/app_decorations.dart';
import 'package:mindclash/core/theme/app_text_styles.dart';
import 'package:mindclash/core/widgets/mindclash_logo.dart';
import 'package:mindclash/features/game_room/presentations/cubits/game_room_cubit.dart';

class MindclashScreen extends StatefulWidget {
  const MindclashScreen({super.key});

  @override
  State<MindclashScreen> createState() => _MindclashScreenState();
}

class _MindclashScreenState extends State<MindclashScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showJoinRoomBottomSheet() {
    _codeController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.elevatedSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.dialpad_rounded, color: AppColors.mintCyan, size: 24),
                const SizedBox(width: 10),
                Text('الانضمام لغرفة التحدي', style: AppTextStyles.h1()),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل كود المعركة المكون من 8 أرقام الذي شاركه معك صديقك:',
              style: AppTextStyles.body(color: Colors.white70),
            ),
            const SizedBox(height: 20),

            // 8-Digit Input Field
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              autofocus: true,
              textAlign: TextAlign.center,
              style: AppTextStyles.digitalCode(color: AppColors.solarCore, fontSize: 26),
              decoration: InputDecoration(
                hintText: '10000000',
                hintStyle: AppTextStyles.digitalCode(color: Colors.white24, fontSize: 26),
                filled: true,
                fillColor: AppColors.inputSurface,
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.mintCyan, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintCyan,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final code = _codeController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(bottomSheetContext);
                  context.read<GameRoomCubit>().joinRoom(code);
                }
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('دخول الغرفة الآن 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('ساحة Mind Clash', style: AppTextStyles.h2()),
        centerTitle: true,
      ),
      body: BlocConsumer<GameRoomCubit, GameRoomState>(
        listener: (context, state) {
          if (state is GameRoomError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.msg),
                backgroundColor: AppColors.cyberCrimson,
              ),
            );
          } else if (state is GameRoomSuccess) {
            if (ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).pushNamed('/room', arguments: state.room);
            }
          }
        },
        builder: (context, state) {
          if (state is GameRoomLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(color: AppColors.electricViolet, strokeWidth: 3),
                  ),
                  const SizedBox(height: 20),
                  Text('جاري الاتصال بالغرفة...', style: AppTextStyles.h2()),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const MindClashLogo(
                  size: 80,
                  showWordmark: true,
                  showTagline: true,
                ),
                const SizedBox(height: 36),

                // Card 1: Host Battle Room
                GestureDetector(
                  onTap: () => context.read<GameRoomCubit>().createRoom(),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF261D4E), Color(0xFF15102E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.electricViolet.withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricViolet.withOpacity(0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.electricViolet.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_moderator_rounded, color: AppColors.solarCore, size: 28),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('المضيف 👑', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('إنشاء غرفة جديدة', style: AppTextStyles.h1()),
                        const SizedBox(height: 6),
                        Text(
                          'أنشئ غرفة خاصة بكود 8 أرقام وتحدَّ صديقك في جولات ذكاء وتضليل حاسمة.',
                          style: AppTextStyles.bodySmall(),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: AppDecorations.primaryButtonStyle(),
                          onPressed: () => context.read<GameRoomCubit>().createRoom(),
                          icon: const Icon(Icons.bolt, size: 20),
                          label: Text('إنشاء الغرفة الآن ⚔️', style: AppTextStyles.button()),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card 2: Join Challenger Room
                GestureDetector(
                  onTap: _showJoinRoomBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.obsidianGlass,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.mintCyan.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mintCyan.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.mintCyan.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.meeting_room_rounded, color: AppColors.mintCyan, size: 28),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.mintCyan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('منافس ⚡', style: TextStyle(color: AppColors.mintCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('الانضمام لغرفة صديق', style: AppTextStyles.h1()),
                        const SizedBox(height: 6),
                        Text(
                          'أدخل كود المعركة المكون من 8 أرقام وادخل ساحة النزال لمواجهة خصمك.',
                          style: AppTextStyles.bodySmall(),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B2D38),
                            foregroundColor: AppColors.mintCyan,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AppColors.mintCyan),
                            ),
                          ),
                          onPressed: _showJoinRoomBottomSheet,
                          icon: const Icon(Icons.key_rounded, size: 20),
                          label: Text('إدخال الكود 🚀', style: AppTextStyles.button(color: AppColors.mintCyan)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}