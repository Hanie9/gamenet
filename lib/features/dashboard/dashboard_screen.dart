import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/responsive_stat_grid.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../models/customer.dart';
import '../../services/app_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeCount = state.gamingActiveSessions.length;
    final customerCount = state.customers.length;
    final todayRevenue = state.todayRevenue;
    final padding = Responsive.pagePadding(context);

    return Padding(
      padding: padding,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'داشبورد',
              subtitle: 'خلاصه وضعیت گیم‌نت',
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsiveStatGrid(
              children: [
                StatCard(
                  icon: Icons.people,
                  label: 'مشتریان',
                  value: toPersianDigits('$customerCount'),
                  color: AppColors.primary,
                ),
                StatCard(
                  icon: Icons.sports_esports,
                  label: 'بازی فعال',
                  value: toPersianDigits('$activeCount'),
                  color: AppColors.gaming,
                ),
                StatCard(
                  icon: Icons.local_cafe,
                  label: 'آیتم کافه',
                  value: toPersianDigits('${state.activeCafeItems.length}'),
                  color: AppColors.accentOrange,
                ),
                StatCard(
                  icon: Icons.payments,
                  label: 'درآمد امروز',
                  value: formatCurrency(
                    todayRevenue,
                    suffix: state.settings.currencyLabel,
                  ),
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'جلسات فعال',
              subtitle: 'مشتریانی که در حال بازی هستند',
            ),
          ),
          if (state.gamingActiveSessions.isEmpty)
            const SliverEmptyFill(
              child: EmptyState(
                icon: Icons.videogame_asset_off,
                title: 'هیچ بازی فعالی وجود ندارد',
                subtitle: 'از بخش بازی، برای مشتری جلسه جدید شروع کنید',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final session = state.gamingActiveSessions[index];
                  final customer = state.customers
                      .where((c) => c.id == session.customerId)
                      .firstOrNull;
                  if (customer == null) return const SizedBox.shrink();
                  return _ActiveSessionTile(
                    customer: customer,
                    playerCount: session.currentPlayerCount,
                    duration:
                        session.activeSegment?.duration ?? Duration.zero,
                  );
                },
                childCount: state.gamingActiveSessions.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _ActiveSessionTile extends StatelessWidget {
  const _ActiveSessionTile({
    required this.customer,
    required this.playerCount,
    required this.duration,
  });

  final Customer customer;
  final int playerCount;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.gaming.withValues(alpha: 0.2),
          child: Text(
            customer.firstName.isNotEmpty ? customer.firstName[0] : '?',
            style: const TextStyle(
              color: AppColors.gaming,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$playerCount نفره — ${formatDuration(duration)}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: AppColors.accent),
              SizedBox(width: 6),
              Text('فعال', style: TextStyle(color: AppColors.accent, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
