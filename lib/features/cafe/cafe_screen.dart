import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/customer_search_picker.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../models/cafe_item.dart';
import '../../models/cafe_order.dart';
import '../../models/customer.dart';
import '../../models/game_session.dart';
import '../../services/app_state.dart';
import '../billing/bill_dialog.dart';
import '../customers/customer_form_dialog.dart';

class CafeScreen extends StatefulWidget {
  const CafeScreen({super.key});

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  String? _selectedCustomerId;
  String _categoryFilter = 'همه';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customers = state.customers;
    final categories = [
      'همه',
      ...state.activeCafeItems.map((i) => i.category).toSet(),
    ];

    if (_selectedCustomerId != null &&
        !customers.any((c) => c.id == _selectedCustomerId)) {
      _selectedCustomerId = null;
    }

    final selectedCustomer = customers
        .where((c) => c.id == _selectedCustomerId)
        .firstOrNull;
    final selectedSession = selectedCustomer == null
        ? null
        : state.sessionForCustomer(selectedCustomer.id);

    final filteredItems = _categoryFilter == 'همه'
        ? state.activeCafeItems
        : state.activeCafeItems
            .where((i) => i.category == _categoryFilter)
            .toList();

    final padding = Responsive.pagePadding(context);
    final hPad = padding.horizontal / 2;
    final contentWidth = MediaQuery.sizeOf(context).width - padding.horizontal;

    if (customers.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(hPad, padding.top, hPad, 0),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'کافه',
                subtitle: 'سفارش‌گیری و افزودن به صورت‌حساب مشتری',
                trailing: ElevatedButton.icon(
                  onPressed: () => CustomerFormDialog.show(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('ثبت مشتری'),
                ),
              ),
            ),
            const SliverEmptyFill(
              child: EmptyState(
                icon: Icons.people_outline,
                title: 'ابتدا یک مشتری ثبت کنید',
                subtitle: 'برای سفارش کافه، مشتری را انتخاب یا ثبت کنید',
              ),
            ),
          ],
        ),
      );
    }

    final cols = Responsive.cafeColumns(contentWidth);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, padding.top, hPad, 0),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'کافه',
              subtitle: 'مشتری را انتخاب کنید و سفارش ثبت کنید',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomerSearchPicker(
                customers: customers,
                selectedId: _selectedCustomerId,
                onSelected: (id) {
                  setState(() => _selectedCustomerId = id);
                  if (id != null) state.selectCustomer(id);
                },
                hint: 'جستجو و انتخاب مشتری...',
                trailingBuilder: (customer) {
                  final session = state.activeSessions
                      .where((s) => s.customerId == customer.id)
                      .firstOrNull;
                  if (session == null) return null;
                  final orderCount = session.cafeOrders.fold(
                    0,
                    (sum, o) => sum + o.quantity,
                  );
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (session.hasActiveGaming)
                        const Icon(
                          Icons.sports_esports,
                          size: 16,
                          color: AppColors.gaming,
                        ),
                      if (orderCount > 0) ...[
                        if (session.hasActiveGaming)
                          const SizedBox(width: 6),
                        Text(
                          '$orderCount آیتم',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          if (selectedCustomer != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _OrderCartPanel(
                  session: selectedSession,
                  customer: selectedCustomer,
                  currency: state.settings.currencyLabel,
                  onCheckout: selectedSession != null &&
                          selectedSession.isCafeOnly &&
                          selectedSession.cafeOrders.isNotEmpty
                      ? () => _checkout(context, selectedSession, selectedCustomer)
                      : null,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final selected = _categoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: selected,
                      onSelected: (_) => setState(() => _categoryFilter = cat),
                      selectedColor:
                          AppColors.accentOrange.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.accentOrange,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (filteredItems.isEmpty)
            const SliverEmptyFill(
              child: EmptyState(
                icon: Icons.restaurant_menu,
                title: 'آیتمی در این دسته نیست',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(bottom: padding.bottom),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: Responsive.cafeAspectRatio(contentWidth),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredItems[index];
                    return _CafeItemCard(
                      item: item,
                      currency: state.settings.currencyLabel,
                      onOrder: selectedCustomer == null
                          ? null
                          : () => _orderItem(context, selectedCustomer, item),
                    );
                  },
                  childCount: filteredItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _orderItem(
    BuildContext context,
    Customer customer,
    CafeItem item,
  ) async {
    try {
      await context.read<AppState>().orderCafeItemForCustomer(
            customerId: customer.id,
            item: item,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  Future<void> _checkout(
    BuildContext context,
    GameSession session,
    Customer customer,
  ) async {
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;
    try {
      final ended = await context.read<AppState>().endSession(session.id);
      await BillDialog.show(
        navigatorContext,
        session: ended,
        customer: customer,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }
}

class _OrderCartPanel extends StatelessWidget {
  const _OrderCartPanel({
    required this.session,
    required this.customer,
    required this.currency,
    this.onCheckout,
  });

  final GameSession? session;
  final Customer customer;
  final String currency;
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    final orders = session?.cafeOrders ?? [];
    final total = orders.fold(0, (sum, o) => sum + o.totalPrice);
    final isGaming = session?.hasActiveGaming ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 20, color: AppColors.accentOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'سفارشات ${customer.fullName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isGaming)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gaming.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'همراه بازی',
                      style: TextStyle(fontSize: 11, color: AppColors.gaming),
                    ),
                  ),
                if (orders.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency(total, suffix: currency),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            if (orders.isEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'هنوز سفارشی ثبت نشده — از منوی پایین آیتم اضافه کنید',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...orders.map(
                (order) => _OrderRow(
                  order: order,
                  currency: currency,
                ),
              ),
              if (onCheckout != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCheckout,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('صدور صورت‌حساب کافه'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.currency,
  });

  final CafeOrder order;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.itemName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  formatCurrency(order.unitPrice, suffix: currency),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _QtyButton(
            icon: Icons.remove,
            onPressed: order.quantity <= 1
                ? null
                : () => state.updateCafeOrderQuantity(
                      order.id,
                      order.quantity - 1,
                    ),
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              toPersianDigits('${order.quantity}'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onPressed: () => state.updateCafeOrderQuantity(
              order.id,
              order.quantity + 1,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => state.removeCafeOrder(order.id),
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'حذف',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null
                ? AppColors.textSecondary.withValues(alpha: 0.4)
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CafeItemCard extends StatelessWidget {
  const _CafeItemCard({
    required this.item,
    required this.currency,
    this.onOrder,
  });

  final CafeItem item;
  final String currency;
  final VoidCallback? onOrder;

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onOrder,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.all(compact ? 6 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 13 : 14,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: compact ? 16 : 17,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatCurrency(item.price, suffix: currency),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: compact ? 15 : 16,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onOrder,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      backgroundColor: AppColors.accentOrange,
                      minimumSize: const Size(0, 26),
                    ),
                    child: const Text('افزودن', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
