import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    final compact = Responsive.isCompact(context);
    final labelSize = compact ? 14.0 : 16.0;
    final valueSize = compact ? 24.0 : 30.0;
    final iconSize = compact ? 28.0 : 34.0;
    final padding = compact ? 16.0 : 22.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 10 : 14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: iconSize),
            ),
            SizedBox(width: compact ? 14 : 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: labelSize,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: valueSize,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
