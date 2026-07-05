import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/customer_search_picker.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../models/customer.dart';
import '../../models/game_session.dart';
import '../../services/app_state.dart';
import '../billing/bill_dialog.dart';
import '../customers/customer_form_dialog.dart';

class GamingScreen extends StatefulWidget {
  const GamingScreen({super.key, this.onNavigateToCafe});

  final VoidCallback? onNavigateToCafe;

  @override
  State<GamingScreen> createState() => _GamingScreenState();
}

class _GamingScreenState extends State<GamingScreen> {
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

    final padding = Responsive.pagePadding(context);

    return Padding(
      padding: padding,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'بازی',
              subtitle: 'شروع، مدیریت و پایان جلسات بازی',
              trailing: ElevatedButton.icon(
                onPressed: () => _showStartDialog(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('شروع بازی جدید'),
              ),
            ),
          ),
          if (state.gamingActiveSessions.isEmpty)
            const SliverEmptyFill(
              child: EmptyState(
                icon: Icons.sports_esports,
                title: 'هیچ بازی فعالی نیست',
                subtitle: 'برای شروع، مشتری را انتخاب و بازی را آغاز کنید',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverToBoxAdapter(
                child: _GamingSessionsGrid(
                  sessions: state.gamingActiveSessions,
                  customers: state.customers,
                  onNavigateToCafe: widget.onNavigateToCafe,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showStartDialog(BuildContext context) async {
    final state = context.read<AppState>();

    if (state.customers.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ابتدا یک مشتری ثبت کنید')));
      await CustomerFormDialog.show(context);
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _StartGameDialog(
        customers: state.customers.where((c) {
          final session = state.sessionForCustomer(c.id);
          return session == null || session.isCafeOnly;
        }).toList(),
      ),
    );
  }
}

class _GamingSessionsGrid extends StatelessWidget {
  const _GamingSessionsGrid({
    required this.sessions,
    required this.customers,
    this.onNavigateToCafe,
  });

  static const double _spacing = 100;
  static const double _runSpacing = 25;

  final List<GameSession> sessions;
  final List<Customer> customers;
  final VoidCallback? onNavigateToCafe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cardWidth = Responsive.gamingCardMaxWidth;
        final maxWidth = constraints.maxWidth;

        final cardsPerRow = math.max(
          1,
          ((maxWidth + _spacing) / (cardWidth + _spacing)).floor(),
        );
        final rowContentWidth =
            cardsPerRow * cardWidth + (cardsPerRow - 1) * _spacing;
        final sidePadding =
            math.max(0.0, (maxWidth - rowContentWidth) / 2);

        final rows = <List<GameSession>>[];
        for (var i = 0; i < sessions.length; i += cardsPerRow) {
          rows.add(
            sessions.sublist(i, math.min(i + cardsPerRow, sessions.length)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              if (rowIndex > 0) const SizedBox(height: _runSpacing),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (var i = 0; i < rows[rowIndex].length; i++) ...[
                      SizedBox(
                        width: cardWidth,
                        child: _sessionCardFor(rows[rowIndex][i]),
                      ),
                      if (i < rows[rowIndex].length - 1)
                        const SizedBox(width: _spacing),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _sessionCardFor(GameSession session) {
    final customer =
        customers.where((c) => c.id == session.customerId).firstOrNull;
    if (customer == null) return const SizedBox.shrink();

    return _SessionCard(
      session: session,
      customer: customer,
      onNavigateToCafe: onNavigateToCafe,
    );
  }
}

class _StartGameDialog extends StatefulWidget {
  const _StartGameDialog({required this.customers});

  final List<Customer> customers;

  @override
  State<_StartGameDialog> createState() => _StartGameDialogState();
}

class _StartGameDialogState extends State<_StartGameDialog> {
  String? _customerId;
  int _playerCount = 1;
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'شروع بازی',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (widget.customers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'همه مشتریان در حال بازی هستند',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  CustomerSearchPicker(
                    customers: widget.customers,
                    selectedId: _customerId,
                    onSelected: (id) => setState(() => _customerId = id),
                    hint: 'جستجو و انتخاب مشتری...',
                  ),
                const SizedBox(height: 20),
                const Text(
                  'تعداد بازیکن',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(4, (i) {
                    final count = i + 1;
                    final selected = _playerCount == count;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: i < 3 ? 8 : 0),
                        child: InkWell(
                          onTap: () => setState(() => _playerCount = count),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.gaming.withValues(alpha: 0.2)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.gaming
                                    : AppColors.border,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: selected
                                      ? AppColors.gaming
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count نفر',
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selected
                                        ? AppColors.gaming
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  formatCurrency(
                                    state.settings.rateForPlayers(count),
                                    suffix: '/ساعت',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _starting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _starting ||
                                _customerId == null ||
                                widget.customers.isEmpty
                            ? null
                            : () => _start(context),
                        icon: const Icon(Icons.play_arrow),
                        label: _starting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('شروع'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    if (_customerId == null) return;
    setState(() => _starting = true);
    try {
      await context.read<AppState>().startSession(
        customerId: _customerId!,
        playerCount: _playerCount,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('بازی شروع شد')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.customer,
    this.onNavigateToCafe,
  });

  final GameSession session;
  final Customer customer;
  final VoidCallback? onNavigateToCafe;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final segment = session.activeSegment;
    final duration = segment?.duration ?? Duration.zero;
    final playerCount = segment?.playerCount ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(Responsive.isCompact(context) ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.gaming.withValues(alpha: 0.2),
                  child: Text(
                    customer.firstName.isNotEmpty ? customer.firstName[0] : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gaming,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        session.serviceType.label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gaming.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$playerCount نفره',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gaming,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatDuration(duration),
                  style: TextStyle(
                    fontSize: Responsive.isCompact(context) ? 28 : 34,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'هزینه فعلی: ${formatCurrency(session.totalCost, suffix: state.settings.currencyLabel)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (session.cafeOrders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: Text(
                    '${session.cafeOrders.length} سفارش کافه',
                    style: const TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'تغییر تعداد بازیکن',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(4, (i) {
                final count = i + 1;
                final selected = playerCount == count;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i < 3 ? 5 : 0),
                    child: InkWell(
                      onTap: selected
                          ? null
                          : () => _showChangePlayerCountDialog(
                              context,
                              playerCount,
                              count,
                            ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.gaming.withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppColors.gaming
                                : AppColors.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: selected
                                  ? AppColors.gaming
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count نفر',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected
                                    ? AppColors.gaming
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              formatCurrency(
                                state.settings.rateForPlayers(count),
                                suffix: '/س',
                              ),
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      state.selectCustomer(customer.id);
                      onNavigateToCafe?.call();
                    },
                    icon: const Icon(Icons.local_cafe, size: 17),
                    label: const Text(
                      'سفارش کافه',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _endSession(context),
                    icon: const Icon(Icons.stop, size: 17),
                    label: const Text(
                      'پایان بازی',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePlayerCountDialog(
    BuildContext context,
    int current,
    int newCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تغییر تعداد بازیکن'),
        content: Text(
          'تایمر فعلی ($current نفره) بسته می‌شود و تایمر جدید برای $newCount نفره با نرخ جدید شروع می‌شود.\n\nادامه می‌دهید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('شروع تایمر جدید'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AppState>().changePlayerCount(
        sessionId: session.id,
        newPlayerCount: newCount,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تایمر $newCount نفره شروع شد')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _endSession(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('پایان بازی'),
        content: const Text('آیا از پایان بازی و صدور صورت‌حساب مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('پایان و صورت‌حساب'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final ended = await context.read<AppState>().endSession(session.id);
      if (context.mounted) {
        await BillDialog.show(context, session: ended, customer: customer);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
