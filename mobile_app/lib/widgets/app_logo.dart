import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.eco,
            color: AppColors.white.withValues(alpha: 0.9),
            size: size * 0.48,
          ),
          Positioned(
            bottom: size * 0.16,
            child: Text(
              'RS',
              style: TextStyle(
                color: AppColors.white,
                fontSize: size * 0.2,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
