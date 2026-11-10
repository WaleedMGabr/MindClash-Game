import 'package:flutter/material.dart';
import 'package:mindclash/core/theme/app_colors.dart';
import 'package:mindclash/core/theme/app_text_styles.dart';

class MindClashLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;

  const MindClashLogo({
    super.key,
    this.size = 80,
    this.showWordmark = true,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glowing Icon Frame
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricViolet.withOpacity(0.35),
                blurRadius: size * 0.35,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.hyperEmerald.withOpacity(0.2),
                blurRadius: size * 0.25,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/images/mindclash_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.obsidianGlass,
                child: Icon(
                  Icons.flash_on,
                  color: AppColors.solarCore,
                  size: size * 0.6,
                ),
              ),
            ),
          ),
        ),

        if (showWordmark) ...[
          SizedBox(height: size * 0.18),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'MIND ',
                  style: AppTextStyles.hero(color: AppColors.textPrimary).copyWith(
                    fontSize: size * 0.32,
                    letterSpacing: 1.5,
                  ),
                ),
                TextSpan(
                  text: 'CLASH',
                  style: AppTextStyles.hero(color: AppColors.solarCore).copyWith(
                    fontSize: size * 0.32,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: AppColors.electricViolet.withOpacity(0.8),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            'OUTSMART • DECEIVE • CONQUER',
            style: AppTextStyles.bodySmall(color: AppColors.neonLavender).copyWith(
              letterSpacing: 2.2,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
