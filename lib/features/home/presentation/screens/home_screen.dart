import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindclash/core/theme/app_colors.dart';
import 'package:mindclash/core/theme/app_decorations.dart';
import 'package:mindclash/core/theme/app_text_styles.dart';
import 'package:mindclash/features/authentication/presentations/cubits/auth_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.elevatedSlate,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تسجيل الخروج', style: AppTextStyles.h2()),
        content: Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟', style: AppTextStyles.body()),
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
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('تسجيل خروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final username = authState is AuthSuccess ? authState.user.username : 'مقاتل';

    return Scaffold(
      backgroundColor: AppColors.voidCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.elevatedSlate,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.electricViolet, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.electricViolet.withOpacity(0.3), blurRadius: 8),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.obsidianGlass,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'M',
                  style: AppTextStyles.button(color: AppColors.solarCore),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(username, style: AppTextStyles.h2(color: Colors.white)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
              tooltip: 'تسجيل خروج',
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ساحة الألعاب التنافسية', style: AppTextStyles.h1()),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.hyperEmerald.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hyperEmerald.withOpacity(0.3)),
                  ),
                  child: Text('مباشر أونلاين 🟢', style: AppTextStyles.bodySmall(color: AppColors.hyperEmerald)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // MindClash Hero Banner Card
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/mindclash'),
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.electricViolet.withOpacity(0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricViolet.withOpacity(0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner Background Image
                      Image.asset(
                        'assets/images/mindclash_banner.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.obsidianGlass),
                      ),

                      // Gradient Overlay for readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.voidCanvas.withOpacity(0.4),
                              AppColors.voidCanvas.withOpacity(0.95),
                            ],
                            stops: const [0.2, 0.6, 1.0],
                          ),
                        ),
                      ),

                      // Content inside Hero Banner
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.electricViolet,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '⚡ معركة 1v1 المباشرة',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mind Clash: صراع العقول',
                              style: AppTextStyles.hero().copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ازرع الفخاخ، اخدع خصمك، واكشف الحقيقة في أشرس معركة عقول ثنائية.',
                              style: AppTextStyles.body(color: Colors.white70).copyWith(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.electricViolet,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pushNamed(context, '/mindclash'),
                              icon: const Icon(Icons.flash_on, color: AppColors.solarCore, size: 20),
                              label: Text('دخول المعركة الآن ⚔️', style: AppTextStyles.button()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
