import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);
    final titleSize = compact ? 20.0 : 24.0;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: compact ? 13 : 14,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: trailing == null
          ? titleBlock
          : LayoutBuilder(
              builder: (context, constraints) {
                final stackTrailing = constraints.maxWidth < 520;
                if (stackTrailing) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      titleBlock,
                      const SizedBox(height: 12),
                      trailing!,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                );
              },
            ),
    );
  }
}
