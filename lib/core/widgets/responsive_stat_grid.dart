import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// گرید آمار با ارتفاع طبیعی — بدون فشردگی و overflow
class ResponsiveStatGrid extends StatelessWidget {
  const ResponsiveStatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.statColumns(constraints.maxWidth);
        const spacing = 16.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}
