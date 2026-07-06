import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamenet/models/app_settings.dart';
import 'package:gamenet/models/cafe_order.dart';
import 'package:gamenet/models/customer.dart';
import 'package:gamenet/models/game_session.dart';
import 'package:gamenet/models/service_type.dart';
import 'package:gamenet/models/session_segment.dart';
import 'package:gamenet/core/utils/jalali_date.dart';
import 'package:gamenet/services/database_service.dart';
import 'package:gamenet/services/excel/excel_data_paths.dart';
import 'package:gamenet/services/monthly_report_service.dart';

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
    final files = dir
        .listSync()
        .map((e) => e.path.split(Platform.pathSeparator).last)
        .toList();
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

  test('generates readable ids and writes Jalali dates to excel', () async {
    final db = DatabaseService.instance;
    final customerId = await db.nextCustomerId();
    expect(customerId, 'USER-0001');

    await db.insertCustomer(
      Customer(
        id: customerId,
        firstName: 'سارا',
        lastName: 'محمدی',
        phone: '09125556666',
        createdAt: DateTime(2026, 1, 1, 10, 30),
      ),
    );

    expect(await db.nextCustomerId(), 'USER-0002');

    final customerFile = File('${tempDir.path}/مشتریان.xlsx');
    final excel = Excel.decodeBytes(await customerFile.readAsBytes());
    final sheet = excel.tables.values.first;
    final idCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
    );
    final dateCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1),
    );

    expect(idCell.value.toString(), contains('USER-0001'));
    expect(dateCell.value.toString(), contains('1404/10/11 10:30:00'));

    final loaded = await db.getCustomer(customerId);
    expect(loaded?.createdAt, DateTime(2026, 1, 1, 10, 30));
  });

  test('segment times keep second precision in excel', () async {
    final db = DatabaseService.instance;
    const customerId = 'USER-0001';
    await db.insertCustomer(
      Customer(
        id: customerId,
        firstName: 'علی',
        lastName: 'رضایی',
        phone: '09120000001',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    const sessionId = 'SESSION-0001';
    const segmentId = 'SEGMENT-0001';
    final start = DateTime(2026, 1, 1, 14, 30, 45);
    final end = DateTime(2026, 1, 1, 14, 35, 20);

    await db.insertSession(
      GameSession(
        id: sessionId,
        customerId: customerId,
        serviceType: ServiceType.gaming,
        status: SessionStatus.active,
        createdAt: start,
        segments: [
          SessionSegment(
            id: segmentId,
            sessionId: sessionId,
            playerCount: 2,
            hourlyRate: 60000,
            startTime: start,
          ),
        ],
      ),
    );

    final active = await db.getActiveSessions();
    expect(active, hasLength(1));
    expect(active.first.segments.single.startTime, start);

    await db.updateSegment(
      SessionSegment(
        id: segmentId,
        sessionId: sessionId,
        playerCount: 2,
        hourlyRate: 60000,
        startTime: start,
        endTime: end,
      ),
    );

    final reloaded = await db.getActiveSessions();
    final segment = reloaded.first.segments.single;
    expect(segment.startTime, start);
    expect(segment.endTime, end);
    expect(segment.duration.inSeconds, 275);
    expect(segment.cost, 4583);
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

  test('ending session writes bill without deadlock', () async {
    final db = DatabaseService.instance;
    const customerId = 'cust-1';
    await db.insertCustomer(
      Customer(
        id: customerId,
        firstName: 'رضا',
        lastName: 'کریمی',
        phone: '09123334444',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

    const sessionId = 'sess-1';
    const segmentId = 'seg-1';
    final start = DateTime(2026, 1, 1, 10, 0);
    final end = DateTime(2026, 1, 1, 11, 0);

    await db.insertSession(
      GameSession(
        id: sessionId,
        customerId: customerId,
        serviceType: ServiceType.gaming,
        status: SessionStatus.active,
        createdAt: start,
        segments: [
          SessionSegment(
            id: segmentId,
            sessionId: sessionId,
            playerCount: 1,
            hourlyRate: 50000,
            startTime: start,
          ),
        ],
      ),
    );

    await db.updateSegment(
      SessionSegment(
        id: segmentId,
        sessionId: sessionId,
        playerCount: 1,
        hourlyRate: 50000,
        startTime: start,
        endTime: end,
      ),
    );

    await db.updateSession(
      GameSession(
        id: sessionId,
        customerId: customerId,
        serviceType: ServiceType.gaming,
        status: SessionStatus.ended,
        createdAt: start,
        endedAt: end,
      ),
    );

    final active = await db.getActiveSessions();
    expect(active, isEmpty);

    final history = await db.getSessionsForCustomer(customerId);
    expect(history, hasLength(1));
    expect(history.first.status, SessionStatus.ended);
    expect(history.first.gamingCost, greaterThan(0));
  });

  test('generates monthly report excel with gaming and cafe stats', () async {
    final db = DatabaseService.instance;
    const customerId = 'USER-0001';
    const sessionId = 'SESSION-0001';
    const segmentId = 'SEGMENT-0001';
    const orderId = 'ORDER-0001';

    await db.insertCustomer(
      Customer(
        id: customerId,
        firstName: 'مینا',
        lastName: 'کاظمی',
        phone: '09124445555',
        createdAt: DateTime(2025, 6, 1),
      ),
    );

    const jalaliYear = 1404;
    const jalaliMonth = 3;
    final playStart = jalaliMonthStart(jalaliYear, jalaliMonth)
        .add(const Duration(hours: 12));
    final playEnd = playStart.add(const Duration(hours: 2));
    final orderTime = playStart.add(const Duration(hours: 3));

    await db.insertSession(
      GameSession(
        id: sessionId,
        customerId: customerId,
        serviceType: ServiceType.gaming,
        status: SessionStatus.active,
        createdAt: playStart,
        segments: [
          SessionSegment(
            id: segmentId,
            sessionId: sessionId,
            playerCount: 1,
            hourlyRate: 60000,
            startTime: playStart,
          ),
        ],
      ),
    );

    await db.updateSegment(
      SessionSegment(
        id: segmentId,
        sessionId: sessionId,
        playerCount: 1,
        hourlyRate: 60000,
        startTime: playStart,
        endTime: playEnd,
      ),
    );

    await db.insertCafeOrder(
      CafeOrder(
        id: orderId,
        sessionId: sessionId,
        itemId: 'ITEM-0001',
        itemName: 'چای',
        quantity: 2,
        unitPrice: 25000,
        createdAt: orderTime,
      ),
    );

    final summary = await MonthlyReportService.instance.generateReport(
      jalaliYear,
      jalaliMonth,
    );

    expect(summary.gamingRevenue, 120000);
    expect(summary.cafeRevenue, 50000);
    expect(summary.totalRevenue, 170000);
    expect(summary.totalPlayTime.inHours, 2);
    expect(summary.cafeItemSales, hasLength(1));
    expect(summary.cafeItemSales.first.itemName, 'چای');
    expect(summary.cafeItemSales.first.quantity, 2);

    final reportFile = File(
      '${tempDir.path}/${monthlyReportFileName(jalaliYear, jalaliMonth)}',
    );
    expect(await reportFile.exists(), isTrue);

    final excel = Excel.decodeBytes(await reportFile.readAsBytes());
    final sheet = excel.tables.values.first;
    final title = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    expect(title.value.toString(), contains('خرداد'));
    expect(title.value.toString(), contains('1404'));
  });
}
