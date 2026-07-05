import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final tight = size.height < 480 || Responsive.isCompact(context);

    final iconSize = tight ? 36.0 : 56.0;
    final padding = tight ? 12.0 : 24.0;
    final titleSize = tight ? 14.0 : 16.0;
    final gap = tight ? 8.0 : 12.0;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
              ),
              SizedBox(height: gap),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                SizedBox(height: gap / 2),
                Text(
                  subtitle!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: tight ? 12 : 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                SizedBox(height: gap * 2),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// پیام خالی داخل sliver — بدون LayoutBuilder
class SliverEmptyFill extends StatelessWidget {
  const SliverEmptyFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: child,
    );
  }
}
