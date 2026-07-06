import 'package:path/path.dart' as p;

import '../models/app_settings.dart';
import '../models/cafe_item.dart';
import '../models/cafe_order.dart';
import '../models/customer.dart';
import '../models/game_session.dart';
import '../models/session_segment.dart';
import 'excel/excel_data_paths.dart';
import 'excel/excel_file_store.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  bool _ready = false;
  Future<void>? _initFuture;

  late ExcelFileStore _customersStore;
  late ExcelFileStore _cafeItemsStore;
  late ExcelFileStore _sessionsStore;
  late ExcelFileStore _segmentsStore;
  late ExcelFileStore _cafeOrdersStore;
  late ExcelFileStore _billsStore;
  late ExcelFileStore _settingsStore;

  var _operationChain = Future<void>.value();

  Future<void> get database async {
    await _ensureReady();
  }

  Future<void> _ensureReady() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _operationChain.then((_) => action());
    _operationChain = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _initialize() async {
    if (_ready) return;

    final dir = await ExcelDataPaths.ensureDataDirectory();

    _customersStore = ExcelFileStore(
      filePath: p.join(dir, ExcelDataPaths.customersFile),
      columns: const [
        'id',
        'first_name',
        'last_name',
        'phone',
        'created_at',
      ],
      headers: const [
        'شناسه',
        'نام',
        'نام خانوادگی',
        'شماره تلفن',
        'تاریخ ثبت',
      ],
    );

    _cafeItemsStore = ExcelFileStore(
      filePath: p.join(dir, ExcelDataPaths.cafeItemsFile),
      columns: const ['id', 'name', 'price', 'category', 'is_active'],
      headers: const [
        'شناسه',
        'نام',
        'قیمت',
        'دسته',
        'فعال',
      ],
    );

    _sessionsStore = ExcelFileStore(
      filePath: p.join(dir, ExcelDataPaths.sessionsFile),
      columns: const [
        'id',
        'customer_id',
        'service_type',
        'status',
        'created_at',
        'ended_at',
      ],
      headers: const [
        'شناسه',
        'شناسه مشتری',
        'نوع سرویس',
        'وضعیت',
        'تاریخ شروع',
        'تاریخ پایان',
      ],
    );

    _segmentsStore = ExcelFileStore(
      filePath: p.join(dir, ExcelDataPaths.segmentsFile),
      columns: const [
        'id',
        'session_id',
        'player_count',
        'hourly_rate',
        'start_time',
        'end_time',
      ],
      headers: const [
        'شناسه',
        'شناسه جلسه',
        'تعداد بازیکن',
        'نرخ ساعتی',
        'شروع',
        'پایان',
      ],
    );

    _cafeOrdersStore = ExcelFileStore(
      filePath: p.join(dir, ExcelDataPaths.cafeOrdersFile),
      columns: const [
        'id',
        'session_id',
        'item_id',
        'item_name',
        'quantity',
        'unit_price',
        'created_at',
      ],
      headers: const [
        'شناسه',
        'شناسه جلسه',
        'شناسه آیتم',
        'نام آیتم',
        'تعداد',
        'قیمت واحد',
        'تاریخ',
      ],
    );

    _billsStore = ExcelFileStore(
      filePath: p.join(dir, ExcelDataPaths.billsFile),
      columns: const [
        'session_id',
        'customer_id',
        'customer_name',
        'gaming_cost',
        'cafe_cost',
        'total_cost',
        'started_at',
        'ended_at',
      ],
      headers: const [
        'شناسه جلسه',
        'شناسه مشتری',
        'نام مشتری',
        'هزینه بازی',
        'هزینه کافه',
        'جمع کل',
        'تاریخ شروع',
        'تاریخ پایان',
      ],
    );

    _settingsStore = ExcelFileStore(
      filePath: p.join(dir, ExcelDataPaths.settingsFile),
      columns: const [
        'hourly_rate_1',
        'hourly_rate_2',
        'hourly_rate_3',
        'hourly_rate_4',
        'currency_label',
      ],
      headers: const [
        'نرخ ۱ نفره',
        'نرخ ۲ نفره',
        'نرخ ۳ نفره',
        'نرخ ۴ نفره',
        'واحد پول',
      ],
    );

    await _customersStore.ensureExists();
    await _cafeItemsStore.ensureExists();
    await _sessionsStore.ensureExists();
    await _segmentsStore.ensureExists();
    await _cafeOrdersStore.ensureExists();
    await _billsStore.ensureExists();
    await _settingsStore.ensureExists();

    await _seedDefaultsIfNeeded();
    _ready = true;
  }

  Future<void> _seedDefaultsIfNeeded() async {
    final settingsRows = await _settingsStore.readAll();
    if (settingsRows.isEmpty) {
      await _settingsStore.writeAll([const AppSettings().toMap()]);
    }

    final cafeRows = await _cafeItemsStore.readAll();
    if (cafeRows.isEmpty) {
      final items = [
        {'id': 'c1', 'name': 'چای', 'price': '25000', 'category': 'نوشیدنی', 'is_active': '1'},
        {'id': 'c2', 'name': 'قهوه', 'price': '45000', 'category': 'نوشیدنی', 'is_active': '1'},
        {'id': 'c3', 'name': 'آب معدنی', 'price': '15000', 'category': 'نوشیدنی', 'is_active': '1'},
        {'id': 'c4', 'name': 'نوشابه', 'price': '30000', 'category': 'نوشیدنی', 'is_active': '1'},
        {'id': 'c5', 'name': 'چیپس', 'price': '35000', 'category': 'تنقلات', 'is_active': '1'},
        {'id': 'c6', 'name': 'پفک', 'price': '30000', 'category': 'تنقلات', 'is_active': '1'},
        {'id': 'c7', 'name': 'ساندویچ', 'price': '85000', 'category': 'غذا', 'is_active': '1'},
        {'id': 'c8', 'name': 'پیتزا', 'price': '120000', 'category': 'غذا', 'is_active': '1'},
      ];
      await _cafeItemsStore.writeAll(items);
    }
  }

  Map<String, dynamic> _parseRow(Map<String, dynamic> row) {
    return row.map((key, value) => MapEntry(key, value.toString()));
  }

  Map<String, dynamic> _parseSessionRow(Map<String, dynamic> row) {
    final map = _parseRow(row);
    if (map['ended_at']?.isEmpty ?? true) {
      map.remove('ended_at');
    }
    return map;
  }

  GameSession _sessionFromRow(Map<String, dynamic> row) =>
      GameSession.fromMap(_parseSessionRow(row));

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.parse(value.toString());
  }

  // ── Customers ──

  Future<List<Customer>> getCustomers() => _serialized(() async {
        await _ensureReady();
        final rows = await _customersStore.readAll();
        return rows
            .map(_parseRow)
            .map(Customer.fromMap)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

  Future<Customer?> getCustomer(String id) => _serialized(() async {
        await _ensureReady();
        final rows = await _customersStore.readAll();
        final row = rows.where((r) => r['id'] == id).firstOrNull;
        if (row == null) return null;
        return Customer.fromMap(_parseRow(row));
      });

  Future<void> insertCustomer(Customer customer) => _serialized(() async {
        await _ensureReady();
        final rows = await _customersStore.readAll();
        rows.add(customer.toMap().map((k, v) => MapEntry(k, v.toString())));
        await _customersStore.writeAll(rows);
      });

  Future<void> updateCustomer(Customer customer) => _serialized(() async {
        await _ensureReady();
        final rows = await _customersStore.readAll();
        final index = rows.indexWhere((r) => r['id'] == customer.id);
        if (index == -1) return;
        rows[index] =
            customer.toMap().map((k, v) => MapEntry(k, v.toString()));
        await _customersStore.writeAll(rows);
      });

  Future<void> deleteCustomer(String id) => _serialized(() async {
        await _ensureReady();
        final rows = await _customersStore.readAll();
        rows.removeWhere((r) => r['id'] == id);
        await _customersStore.writeAll(rows);
      });

  // ── Cafe Items ──

  Future<List<CafeItem>> getCafeItems() => _serialized(() async {
        await _ensureReady();
        final rows = await _cafeItemsStore.readAll();
        return rows.map((row) {
          final map = _parseRow(row);
          map['price'] = _asInt(map['price']);
          map['is_active'] = _asInt(map['is_active']);
          return CafeItem.fromMap(map);
        }).toList()
          ..sort((a, b) {
            final c = a.category.compareTo(b.category);
            return c != 0 ? c : a.name.compareTo(b.name);
          });
      });

  Future<void> insertCafeItem(CafeItem item) => _serialized(() async {
        await _ensureReady();
        final rows = await _cafeItemsStore.readAll();
        rows.add(item.toMap().map((k, v) => MapEntry(k, v.toString())));
        await _cafeItemsStore.writeAll(rows);
      });

  Future<void> updateCafeItem(CafeItem item) => _serialized(() async {
        await _ensureReady();
        final rows = await _cafeItemsStore.readAll();
        final index = rows.indexWhere((r) => r['id'] == item.id);
        if (index == -1) return;
        rows[index] = item.toMap().map((k, v) => MapEntry(k, v.toString()));
        await _cafeItemsStore.writeAll(rows);
      });

  Future<void> deleteCafeItem(String id) => _serialized(() async {
        await _ensureReady();
        final rows = await _cafeItemsStore.readAll();
        rows.removeWhere((r) => r['id'] == id);
        await _cafeItemsStore.writeAll(rows);
      });

  // ── Sessions ──

  Future<void> insertSession(GameSession session) => _serialized(() async {
        await _ensureReady();
        final sessions = await _sessionsStore.readAll();
        sessions.add(
          session.toMap().map((k, v) => MapEntry(k, v?.toString() ?? '')),
        );
        await _sessionsStore.writeAll(sessions);

        if (session.segments.isNotEmpty) {
          final segments = await _segmentsStore.readAll();
          for (final segment in session.segments) {
            segments.add(
              segment.toMap().map((k, v) => MapEntry(k, v?.toString() ?? '')),
            );
          }
          await _segmentsStore.writeAll(segments);
        }
      });

  Future<void> updateSession(GameSession session) => _serialized(() async {
        await _ensureReady();
        final sessions = await _sessionsStore.readAll();
        final index = sessions.indexWhere((r) => r['id'] == session.id);
        if (index == -1) return;
        sessions[index] =
            session.toMap().map((k, v) => MapEntry(k, v?.toString() ?? ''));
        await _sessionsStore.writeAll(sessions);

        if (!session.isActive && session.endedAt != null) {
          await _upsertBill(session);
        }
      });

  Future<void> insertSegment(SessionSegment segment) => _serialized(() async {
        await _ensureReady();
        final rows = await _segmentsStore.readAll();
        rows.add(
          segment.toMap().map((k, v) => MapEntry(k, v?.toString() ?? '')),
        );
        await _segmentsStore.writeAll(rows);
      });

  Future<void> updateSegment(SessionSegment segment) => _serialized(() async {
        await _ensureReady();
        final rows = await _segmentsStore.readAll();
        final index = rows.indexWhere((r) => r['id'] == segment.id);
        if (index == -1) return;
        rows[index] =
            segment.toMap().map((k, v) => MapEntry(k, v?.toString() ?? ''));
        await _segmentsStore.writeAll(rows);
      });

  Future<void> insertCafeOrder(CafeOrder order) => _serialized(() async {
        await _ensureReady();
        final rows = await _cafeOrdersStore.readAll();
        rows.add(order.toMap().map((k, v) => MapEntry(k, v.toString())));
        await _cafeOrdersStore.writeAll(rows);
      });

  Future<void> updateCafeOrder(CafeOrder order) => _serialized(() async {
        await _ensureReady();
        final rows = await _cafeOrdersStore.readAll();
        final index = rows.indexWhere((r) => r['id'] == order.id);
        if (index == -1) return;
        rows[index] = order.toMap().map((k, v) => MapEntry(k, v.toString()));
        await _cafeOrdersStore.writeAll(rows);
      });

  Future<void> deleteCafeOrder(String id) => _serialized(() async {
        await _ensureReady();
        final rows = await _cafeOrdersStore.readAll();
        rows.removeWhere((r) => r['id'] == id);
        await _cafeOrdersStore.writeAll(rows);
      });

  Future<CafeOrder?> getCafeOrder(String id) => _serialized(() async {
        await _ensureReady();
        final rows = await _cafeOrdersStore.readAll();
        final row = rows.where((r) => r['id'] == id).firstOrNull;
        if (row == null) return null;
        final map = _parseRow(row);
        map['quantity'] = _asInt(map['quantity']);
        map['unit_price'] = _asInt(map['unit_price']);
        return CafeOrder.fromMap(map);
      });

  Future<List<GameSession>> getSessionsForCustomer(String customerId) =>
      _serialized(() async {
        await _ensureReady();
        final rows = await _sessionsStore.readAll();
        final sessions = <GameSession>[];
        for (final row in rows.where((r) => r['customer_id'] == customerId)) {
          sessions.add(await _loadSessionDetails(_sessionFromRow(row)));
        }
        sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sessions;
      });

  Future<List<GameSession>> getActiveSessions() => _serialized(() async {
        await _ensureReady();
        final rows = await _sessionsStore.readAll();
        final sessions = <GameSession>[];
        for (final row in rows.where((r) => r['status'] == 'active')) {
          sessions.add(await _loadSessionDetails(_sessionFromRow(row)));
        }
        sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sessions;
      });

  Future<List<GameSession>> getSessionsEndedSince(DateTime since) =>
      _serialized(() async {
        await _ensureReady();
        final rows = await _sessionsStore.readAll();
        final sessions = <GameSession>[];
        for (final row in rows.where((r) => r['status'] == 'ended')) {
          final map = _parseRow(row);
          final endedAt = map['ended_at'];
          if (endedAt == null || endedAt.isEmpty) continue;
          if (DateTime.parse(endedAt).isBefore(since)) continue;
          sessions.add(await _loadSessionDetails(_sessionFromRow(map)));
        }
        sessions.sort((a, b) {
          final ae = a.endedAt ?? a.createdAt;
          final be = b.endedAt ?? b.createdAt;
          return be.compareTo(ae);
        });
        return sessions;
      });

  Future<GameSession?> getSession(String id) => _serialized(() async {
        await _ensureReady();
        final rows = await _sessionsStore.readAll();
        final row = rows.where((r) => r['id'] == id).firstOrNull;
        if (row == null) return null;
        return _loadSessionDetails(_sessionFromRow(row));
      });

  Future<GameSession> _loadSessionDetails(GameSession session) async {
    final segmentRows = await _segmentsStore.readAll();
    final orderRows = await _cafeOrdersStore.readAll();

    final segments = segmentRows
        .where((r) => r['session_id'] == session.id)
        .map(_parseRow)
        .map((map) {
          map['player_count'] = _asInt(map['player_count']);
          map['hourly_rate'] = _asInt(map['hourly_rate']);
          if (map['end_time']?.isEmpty ?? true) {
            map['end_time'] = null;
          }
          return SessionSegment.fromMap(map);
        })
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final cafeOrders = orderRows
        .where((r) => r['session_id'] == session.id)
        .map(_parseRow)
        .map((map) {
          map['quantity'] = _asInt(map['quantity']);
          map['unit_price'] = _asInt(map['unit_price']);
          return CafeOrder.fromMap(map);
        })
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return session.copyWith(segments: segments, cafeOrders: cafeOrders);
  }

  Future<void> _upsertBill(GameSession session) async {
    final loaded = await _loadSessionDetails(session);
    final customer = await getCustomer(loaded.customerId);
    final customerName = customer?.fullName ?? 'نامشخص';

    final bill = {
      'session_id': loaded.id,
      'customer_id': loaded.customerId,
      'customer_name': customerName,
      'gaming_cost': '${loaded.gamingCost}',
      'cafe_cost': '${loaded.cafeCost}',
      'total_cost': '${loaded.totalCost}',
      'started_at': loaded.createdAt.toIso8601String(),
      'ended_at': loaded.endedAt?.toIso8601String() ?? '',
    };

    final rows = await _billsStore.readAll();
    final index = rows.indexWhere((r) => r['session_id'] == loaded.id);
    if (index == -1) {
      rows.add(bill);
    } else {
      rows[index] = bill;
    }
    await _billsStore.writeAll(rows);
  }

  // ── Settings ──

  Future<AppSettings> getSettings() => _serialized(() async {
        await _ensureReady();
        final rows = await _settingsStore.readAll();
        if (rows.isEmpty) return const AppSettings();
        final map = _parseRow(rows.first);
        map['hourly_rate_1'] = _asInt(map['hourly_rate_1']);
        map['hourly_rate_2'] = _asInt(map['hourly_rate_2']);
        map['hourly_rate_3'] = _asInt(map['hourly_rate_3']);
        map['hourly_rate_4'] = _asInt(map['hourly_rate_4']);
        return AppSettings.fromMap(map);
      });

  Future<void> saveSettings(AppSettings settings) => _serialized(() async {
        await _ensureReady();
        await _settingsStore.writeAll([
          settings.toMap().map((k, v) => MapEntry(k, v.toString())),
        ]);
      });

  Future<String> getDataDirectoryPath() async {
    await _ensureReady();
    return ExcelDataPaths.documentsDirectory();
  }

  /// فقط برای تست
  void resetForTest() {
    _ready = false;
    _initFuture = null;
    _operationChain = Future<void>.value();
  }
}
