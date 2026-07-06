import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../models/customer.dart';
import '../../services/app_state.dart';
import 'customer_detail_screen.dart';
import 'customer_form_dialog.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _filtered(AppState state) {
    if (_query.isEmpty) return state.customers;
    final q = _query.toLowerCase();
    return state.customers.where((c) {
      return c.fullName.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final customers = _filtered(state);
    final padding = Responsive.pagePadding(context);
    final hPad = padding.horizontal / 2;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, padding.top, hPad, 0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'مشتریان',
              subtitle: 'داده‌ها در فایل «مشتریان.xlsx» در Documents/201 ذخیره می‌شوند',
              trailing: ElevatedButton.icon(
                onPressed: () => CustomerFormDialog.show(context),
                icon: const Icon(Icons.person_add),
                label: const Text('مشتری جدید'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'جستجو بر اساس نام یا شماره تلفن...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (customers.isEmpty)
            SliverEmptyFill(
              child: EmptyState(
                icon: Icons.people_outline,
                title: _query.isEmpty
                    ? 'هنوز مشتری ثبت نشده'
                    : 'نتیجه‌ای یافت نشد',
                subtitle:
                    _query.isEmpty ? 'با دکمه «مشتری جدید» شروع کنید' : null,
                action: _query.isEmpty
                    ? ElevatedButton.icon(
                        onPressed: () => CustomerFormDialog.show(context),
                        icon: const Icon(Icons.person_add),
                        label: const Text('ثبت مشتری'),
                      )
                    : null,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final customer = customers[index];
                  final hasActive =
                      state.sessionForCustomer(customer.id) != null;

                  return _CustomerListTile(
                    customer: customer,
                    hasActive: hasActive,
                    onTap: () {
                      state.selectCustomer(customer.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerDetailScreen(customer: customer),
                        ),
                      );
                    },
                  );
                },
                childCount: customers.length,
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: padding.bottom)),
        ],
      ),
    );
  }
}

class _CustomerListTile extends StatelessWidget {
  const _CustomerListTile({
    required this.customer,
    required this.hasActive,
    required this.onTap,
  });

  final Customer customer;
  final bool hasActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    customer.firstName.isNotEmpty
                        ? customer.firstName[0]
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (hasActive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'در حال بازی',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              customer.fullName,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                decoration: TextDecoration.none,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.phone,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_left,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
