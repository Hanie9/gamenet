import 'package:flutter/material.dart';

/// محتوای صفحه را از بالا شروع می‌کند (نه وسط صفحه).
class TopAlignedScrollView extends StatelessWidget {
  const TopAlignedScrollView({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: padding,
        child: child,
      ),
    );
  }
}
