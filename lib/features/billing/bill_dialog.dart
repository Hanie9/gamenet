import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer.dart';
import '../../models/game_session.dart';
import '../../services/app_state.dart';

class BillDialog extends StatelessWidget {
  const BillDialog({
    super.key,
    required this.session,
    required this.customer,
  });

  final GameSession session;
  final Customer customer;

  static Future<void> show(
    BuildContext context, {
    required GameSession session,
    required Customer customer,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BillDialog(session: session, customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppState>().settings;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long, color: AppColors.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'صورت‌حساب',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          customer.fullName,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'بازی',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...session.segments.map((segment) => _BillRow(
                    label:
                        '${segment.playerCount} نفره — ${formatDuration(segment.duration)}',
                    value: formatCurrency(
                      segment.cost,
                      suffix: settings.currencyLabel,
                    ),
                  )),
              if (session.cafeOrders.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'کافه',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...session.cafeOrders.map(
                  (order) => _BillRow(
                    label: '${order.itemName} × ${order.quantity}',
                    value: formatCurrency(
                      order.totalPrice,
                      suffix: settings.currencyLabel,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _BillRow(
                label: 'جمع کل',
                value: formatCurrency(
                  session.totalCost,
                  suffix: settings.currencyLabel,
                ),
                isTotal: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('بستن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
