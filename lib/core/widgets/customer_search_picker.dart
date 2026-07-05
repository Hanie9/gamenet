import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/customer.dart';
import '../theme/app_theme.dart';

/// انتخاب مشتری با جستجوی سریع بر اساس نام یا شماره تلفن
class CustomerSearchPicker extends StatefulWidget {
  const CustomerSearchPicker({
    super.key,
    required this.customers,
    required this.selectedId,
    required this.onSelected,
    this.hint = 'جستجو نام یا شماره تلفن...',
    this.maxVisibleItems = 4,
    this.trailingBuilder,
    this.emptyMessage = 'مشتری‌ای یافت نشد',
  });

  final List<Customer> customers;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String hint;
  final int maxVisibleItems;
  final Widget? Function(Customer customer)? trailingBuilder;
  final String emptyMessage;

  @override
  State<CustomerSearchPicker> createState() => _CustomerSearchPickerState();
}

class _CustomerSearchPickerState extends State<CustomerSearchPicker> {
  static const double _itemExtent = 56;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filtered {
    if (_query.isEmpty) return widget.customers;
    final q = _query.toLowerCase();
    return widget.customers.where((c) {
      return c.fullName.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();
  }

  Customer? get _selected => widget.customers
      .where((c) => c.id == widget.selectedId)
      .firstOrNull;

  double _listHeightFor(int count) {
    final visible = math.min(count, widget.maxVisibleItems);
    return visible * _itemExtent;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selected = _selected;
    final scrollable = filtered.length > widget.maxVisibleItems;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selected != null) ...[
              Material(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          selected.firstName.isNotEmpty
                              ? selected.firstName[0]
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
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
                              selected.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              selected.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.trailingBuilder != null) ...[
                        widget.trailingBuilder!(selected) ??
                            const SizedBox.shrink(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            if (_query.isNotEmpty || selected == null) ...[
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    widget.emptyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                SizedBox(
                  height: _listHeightFor(filtered.length),
                  child: Scrollbar(
                    thumbVisibility: scrollable,
                    child: ListView.separated(
                      primary: false,
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        final isSelected = customer.id == widget.selectedId;

                        return SizedBox(
                          height: _itemExtent - 1,
                          child: Material(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                widget.onSelected(customer.id);
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      child: Text(
                                        customer.firstName.isNotEmpty
                                            ? customer.firstName[0]
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          Text(
                                            customer.phone,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.trailingBuilder != null)
                                      widget.trailingBuilder!(customer) ??
                                          const SizedBox.shrink(),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
