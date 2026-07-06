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
import '../../models/game_session.dart';
import '../../services/app_state.dart';
import '../billing/bill_dialog.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final Customer customer;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<GameSession>? _history;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final sessions = await context
          .read<AppState>()
          .getCustomerHistory(widget.customer.id);
      if (!mounted) return;
      setState(() {
        _history = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در بارگذاری تاریخچه: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = _history != null
        ? state.statsForCustomer(_history!)
        : null;

    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        widget.customer.firstName.isNotEmpty
                            ? widget.customer.firstName[0]
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.customer.fullName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            widget.customer.phone,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (stats != null) ...[
                  ResponsiveStatGrid(
                    children: [
                      StatCard(
                        icon: Icons.sports_esports,
                        label: 'تعداد بازی',
                        value: toPersianDigits('${stats.totalGames}'),
                        color: AppColors.gaming,
                      ),
                      StatCard(
                        icon: Icons.timer,
                        label: 'مجموع زمان بازی',
                        value: formatDuration(stats.totalPlayTime),
                        color: AppColors.primary,
                      ),
                      StatCard(
                        icon: Icons.receipt,
                        label: 'صورت‌حساب‌ها',
                        value: toPersianDigits('${stats.totalBills}'),
                        color: AppColors.accentOrange,
                      ),
                      StatCard(
                        icon: Icons.payments,
                        label: 'مجموع پرداخت',
                        value: formatCurrency(
                          stats.totalSpent,
                          suffix: state.settings.currencyLabel,
                        ),
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SectionHeader(
                    title: 'تاریخچه',
                    subtitle: 'بازی‌ها و صورت‌حساب‌های قبلی',
                  ),
                ],
              ]),
            ),
          ),
          if (!_loading && stats != null && _history!.isEmpty)
            const SliverEmptyFill(
              child: EmptyState(
                icon: Icons.history,
                title: 'هنوز بازی‌ای ثبت نشده',
              ),
            )
          else if (!_loading && stats != null && _history!.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                0,
                padding.right,
                padding.bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = _history![index];
                    return _HistoryTile(
                      session: session,
                      customer: widget.customer,
                      currency: state.settings.currencyLabel,
                    );
                  },
                  childCount: _history!.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.customer,
    required this.currency,
  });

  final GameSession session;
  final Customer customer;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isActive = session.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: isActive
              ? null
              : () => BillDialog.show(
                    context,
                    session: session,
                    customer: customer,
                  ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.play_circle : Icons.receipt_long,
                  color: isActive ? AppColors.accent : AppColors.accentOrange,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.serviceType.label,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDateTime(session.createdAt)} — ${formatDuration(session.totalDuration)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatCurrency(session.totalCost, suffix: currency),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (!isActive) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
