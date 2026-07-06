import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/section_header.dart';
import '../../models/cafe_item.dart';
import '../../services/app_state.dart';
import '../../services/data_folder_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rate1 = TextEditingController();
  final _rate2 = TextEditingController();
  final _rate3 = TextEditingController();
  final _rate4 = TextEditingController();
  bool _ratesLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rate1.dispose();
    _rate2.dispose();
    _rate3.dispose();
    _rate4.dispose();
    super.dispose();
  }

  void _loadRates(AppState state) {
    if (_ratesLoaded) return;
    _rate1.text = '${state.settings.hourlyRate1}';
    _rate2.text = '${state.settings.hourlyRate2}';
    _rate3.text = '${state.settings.hourlyRate3}';
    _rate4.text = '${state.settings.hourlyRate4}';
    _ratesLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _loadRates(state);

    final padding = Responsive.pagePadding(context);
    final hPad = padding.horizontal / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, padding.top, hPad, 0),
          child: const SectionHeader(
            title: 'مدیریت',
            subtitle: 'تعریف قیمت‌ها و مدیریت منوی کافه',
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'نرخ بازی'),
              Tab(text: 'منوی کافه'),
              Tab(text: 'فایل‌های داده'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _RatesTab(
                rate1: _rate1,
                rate2: _rate2,
                rate3: _rate3,
                rate4: _rate4,
                currency: state.settings.currencyLabel,
                onSave: () => _saveRates(context),
              ),
              _CafeManagementTab(items: state.cafeItems),
              _DataFilesTab(dataPathFuture: state.dataDirectoryPath),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveRates(BuildContext context) async {
    final r1 = int.tryParse(_rate1.text);
    final r2 = int.tryParse(_rate2.text);
    final r3 = int.tryParse(_rate3.text);
    final r4 = int.tryParse(_rate4.text);

    if ([r1, r2, r3, r4].any((r) => r == null || r <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قیمت‌های معتبر وارد کنید')),
      );
      return;
    }

    final current = context.read<AppState>().settings;
    await context.read<AppState>().saveSettings(
          current.copyWith(
            hourlyRate1: r1!,
            hourlyRate2: r2!,
            hourlyRate3: r3!,
            hourlyRate4: r4!,
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نرخ‌ها ذخیره شد')),
      );
    }
  }
}

class _RatesTab extends StatelessWidget {
  const _RatesTab({
    required this.rate1,
    required this.rate2,
    required this.rate3,
    required this.rate4,
    required this.currency,
    required this.onSave,
  });

  final TextEditingController rate1;
  final TextEditingController rate2;
  final TextEditingController rate3;
  final TextEditingController rate4;
  final String currency;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);
    return SingleChildScrollView(
      padding: padding,
      child: Card(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نرخ ساعتی بازی (بر اساس تعداد بازیکن)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'این قیمت‌ها هنگام شروع بازی و تغییر تعداد بازیکن اعمال می‌شوند.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _RateField(controller: rate1, label: '۱ نفره', currency: currency),
              const SizedBox(height: 16),
              _RateField(controller: rate2, label: '۲ نفره', currency: currency),
              const SizedBox(height: 16),
              _RateField(controller: rate3, label: '۳ نفره', currency: currency),
              const SizedBox(height: 16),
              _RateField(controller: rate4, label: '۴ نفره', currency: currency),
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save),
                  label: const Text('ذخیره نرخ‌ها'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateField extends StatelessWidget {
  const _RateField({
    required this.controller,
    required this.label,
    required this.currency,
  });

  final TextEditingController controller;
  final String label;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              suffixText: currency,
              hintText: 'قیمت ساعتی',
            ),
          ),
        ),
      ],
    );
  }
}

class _CafeManagementTab extends StatelessWidget {
  const _CafeManagementTab({required this.items});

  final List<CafeItem> items;

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);
    final hPad = padding.horizontal / 2;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () => _showItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('آیتم جدید'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, padding.bottom),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.category),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatCurrency(
                          item.price,
                          suffix: context
                              .watch<AppState>()
                              .settings
                              .currencyLabel,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            _showItemDialog(context, item: item);
                          } else if (action == 'toggle') {
                            await context.read<AppState>().updateCafeItem(
                                  item.copyWith(isActive: !item.isActive),
                                );
                          } else if (action == 'delete') {
                            await context
                                .read<AppState>()
                                .deleteCafeItem(item.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('ویرایش'),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(
                              item.isActive ? 'غیرفعال' : 'فعال',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('حذف'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showItemDialog(BuildContext context, {CafeItem? item}) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl =
        TextEditingController(text: item != null ? '${item.price}' : '');
    final categoryCtrl = TextEditingController(text: item?.category ?? 'نوشیدنی');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(item == null ? 'آیتم جدید' : 'ویرایش آیتم'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'نام'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'قیمت'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'دسته‌بندی'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = int.tryParse(priceCtrl.text);
              if (nameCtrl.text.isEmpty || price == null) return;

              final appState = context.read<AppState>();
              if (item == null) {
                await appState.addCafeItem(
                  name: nameCtrl.text,
                  price: price,
                  category: categoryCtrl.text,
                );
              } else {
                await appState.updateCafeItem(
                  item.copyWith(
                    name: nameCtrl.text,
                    price: price,
                    category: categoryCtrl.text,
                  ),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    priceCtrl.dispose();
    categoryCtrl.dispose();
  }
}

class _DataFilesTab extends StatelessWidget {
  const _DataFilesTab({required this.dataPathFuture});

  final Future<String> dataPathFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: dataPathFuture,
      builder: (context, snapshot) {
        final path = snapshot.data;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ذخیره‌سازی اکسل',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'همه داده‌های اپ به‌صورت خودکار در فایل‌های اکسل ذخیره می‌شوند. '
                      'با هر تغییر، همان فایل به‌روز می‌شود.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    if (path != null) ...[
                      const SizedBox(height: 12),
                      SelectableText(
                        path,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await DataFolderService.openInFileManager();
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('باز کردن پوشه داده'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'فایل‌ها',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...DataFolderService.dataFiles.map(
              (file) => ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(file),
                dense: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
