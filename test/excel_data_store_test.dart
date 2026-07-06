import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamenet/models/app_settings.dart';
import 'package:gamenet/models/customer.dart';
import 'package:gamenet/services/database_service.dart';
import 'package:gamenet/services/excel/excel_data_paths.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    DatabaseService.instance.resetForTest();
    tempDir = await Directory.systemTemp.createTemp('gamenet_excel_test_');
    ExcelDataPaths.testOverride = tempDir.path;
    await DatabaseService.instance.database;
  });

  tearDown(() async {
    DatabaseService.instance.resetForTest();
    ExcelDataPaths.testOverride = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('creates excel files on startup', () async {
    final dir = Directory(tempDir.path);
    final files = dir.listSync().map((e) => e.path.split(Platform.pathSeparator).last).toList();
    expect(files, contains('مشتریان.xlsx'));
    expect(files, contains('صورتحساب‌ها.xlsx'));
    expect(files, contains('تنظیمات.xlsx'));
  });

  test('customer CRUD writes to excel file', () async {
    final db = DatabaseService.instance;
    final customer = Customer(
      id: 'c-1',
      firstName: 'علی',
      lastName: 'احمدی',
      phone: '09120000000',
      createdAt: DateTime(2026, 1, 1),
    );

    await db.insertCustomer(customer);
    final customers = await db.getCustomers();
    expect(customers, hasLength(1));
    expect(customers.first.fullName, 'علی احمدی');

    await db.updateCustomer(customer.copyWith(phone: '09121111111'));
    final updated = await db.getCustomer('c-1');
    expect(updated?.phone, '09121111111');

    await db.deleteCustomer('c-1');
    final afterDelete = await db.getCustomers();
    expect(afterDelete, isEmpty);
  });

  test('settings are persisted in excel', () async {
    final db = DatabaseService.instance;
    const settings = AppSettings(
      hourlyRate1: 60000,
      hourlyRate2: 90000,
      hourlyRate3: 110000,
      hourlyRate4: 130000,
      currencyLabel: 'تومان',
    );
    await db.saveSettings(settings);
    final loaded = await db.getSettings();
    expect(loaded.hourlyRate1, 60000);
    expect(loaded.hourlyRate4, 130000);
  });
}
