import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Mascota provisional de PrecioBencina (gotita de bencina sonriente).
/// Reemplazar por la ilustración final cuando esté lista (ver assets/mascot/).
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text('⛽', style: TextStyle(fontSize: size * 0.55)),
    );
  }
}
