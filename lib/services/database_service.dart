import 'package:path/path.dart' as p;

import '../core/utils/jalali_date.dart';
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

    final dirs = await ExcelDataPaths.ensureDataDirectories();

    List<String> pathsFor(String fileName) =>
        dirs.map((dir) => p.join(dir, fileName)).toList();

    _customersStore = ExcelFileStore(
      filePaths: pathsFor(ExcelDataPaths.customersFile),
      columns: const ['id', 'first_name', 'last_name', 'phone', 'created_at'],
      headers: const [
        'شناسه',
        'نام',
        'نام خانوادگی',
        'شماره تلفن',
        'تاریخ ثبت',
      ],
    );

    _cafeItemsStore = ExcelFileStore(
      filePaths: pathsFor(ExcelDataPaths.cafeItemsFile),
      columns: const ['id', 'name', 'price', 'category', 'is_active'],
      headers: const ['شناسه', 'نام', 'قیمت', 'دسته', 'فعال'],
    );

    _sessionsStore = ExcelFileStore(
      filePaths: pathsFor(ExcelDataPaths.sessionsFile),
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
      filePaths: pathsFor(ExcelDataPaths.segmentsFile),
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
      filePaths: pathsFor(ExcelDataPaths.cafeOrdersFile),
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
      filePaths: pathsFor(ExcelDataPaths.billsFile),
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
      filePaths: pathsFor(ExcelDataPaths.settingsFile),
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
    await _migrateReadableIds();
    await _normalizeDateFiles();
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
        {
          'id': 'ITEM-0001',
          'name': 'چای',
          'price': '25000',
          'category': 'نوشیدنی',
          'is_active': '1',
        },
        {
          'id': 'ITEM-0002',
          'name': 'قهوه',
          'price': '45000',
          'category': 'نوشیدنی',
          'is_active': '1',
        },
        {
          'id': 'ITEM-0003',
          'name': 'آب معدنی',
          'price': '15000',
          'category': 'نوشیدنی',
          'is_active': '1',
        },
        {
          'id': 'ITEM-0004',
          'name': 'نوشابه',
          'price': '30000',
          'category': 'نوشیدنی',
          'is_active': '1',
        },
        {
          'id': 'ITEM-0005',
          'name': 'چیپس',
          'price': '35000',
          'category': 'تنقلات',
          'is_active': '1',
        },
        {
          'id': 'ITEM-0006',
          'name': 'پفک',
          'price': '30000',
          'category': 'تنقلات',
          'is_active': '1',
        },
        {
          'id': 'ITEM-0007',
          'name': 'ساندویچ',
          'price': '85000',
          'category': 'غذا',
          'is_active': '1',
        },
        {
          'id': 'ITEM-0008',
          'name': 'پیتزا',
          'price': '120000',
          'category': 'غذا',
          'is_active': '1',
        },
      ];
      await _cafeItemsStore.writeAll(items);
    }
  }

  Map<String, dynamic> _parseRow(Map<String, dynamic> row) {
    return row.map((key, value) => MapEntry(key, value.toString()));
  }

  static const _customerDateColumns = {'created_at'};
  static const _sessionDateColumns = {'created_at', 'ended_at'};
  static const _segmentDateColumns = {'start_time', 'end_time'};
  static const _orderDateColumns = {'created_at'};
  static const _billDateColumns = {'started_at', 'ended_at'};

  Map<String, dynamic> _excelRow(
    Map<String, dynamic> row, {
    Set<String> dateColumns = const {},
  }) {
    return row.map((key, value) {
      if (value == null) return MapEntry(key, '');
      if (dateColumns.contains(key)) {
        if (value is DateTime) {
          return MapEntry(key, formatJalaliDateTime(value));
        }
        final text = value.toString();
        if (text.isEmpty) return MapEntry(key, '');
        return MapEntry(key, formatJalaliDateTime(parseFlexibleDateTime(text)));
      }
      return MapEntry(key, value.toString());
    });
  }

  Map<String, dynamic> _modelRow(
    Map<String, dynamic> row, {
    Set<String> dateColumns = const {},
  }) {
    final map = _parseRow(row);
    for (final key in dateColumns) {
      final value = map[key];
      if (value == null || value.isEmpty) continue;
      map[key] = parseFlexibleDateTime(value).toIso8601String();
    }
    return map;
  }

  Map<String, dynamic> _parseSessionRow(Map<String, dynamic> row) {
    final map = _modelRow(row, dateColumns: _sessionDateColumns);
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

  int _nextNumber(Iterable<String> ids, String prefix) {
    var max = 0;
    final pattern = RegExp('^${RegExp.escape(prefix)}-(\\d+)\$');
    for (final id in ids) {
      final match = pattern.firstMatch(id);
      if (match == null) continue;
      final number = int.tryParse(match.group(1)!);
      if (number != null && number > max) max = number;
    }
    return max + 1;
  }

  String _formatId(String prefix, int number) =>
      '$prefix-${number.toString().padLeft(4, '0')}';

  bool _isReadableId(String id, String prefix) {
    return RegExp('^${RegExp.escape(prefix)}-\\d+\$').hasMatch(id);
  }

  Map<String, String> _migrateIds(
    List<Map<String, dynamic>> rows,
    String prefix,
  ) {
    final usedIds = rows.map((row) => '${row['id']}').toSet();
    var next = _nextNumber(usedIds, prefix);
    final idMap = <String, String>{};

    for (final row in rows) {
      final oldId = '${row['id']}';
      if (oldId.isEmpty || _isReadableId(oldId, prefix)) continue;

      String newId;
      do {
        newId = _formatId(prefix, next++);
      } while (usedIds.contains(newId));

      row['id'] = newId;
      usedIds.add(newId);
      idMap[oldId] = newId;
    }

    return idMap;
  }

  void _replaceReferences(
    List<Map<String, dynamic>> rows,
    String column,
    Map<String, String> idMap,
  ) {
    if (idMap.isEmpty) return;
    for (final row in rows) {
      final current = '${row[column]}';
      final updated = idMap[current];
      if (updated != null) row[column] = updated;
    }
  }

  Future<void> _migrateReadableIds() async {
    final customerRows = await _customersStore.readAll();
    final cafeItemRows = await _cafeItemsStore.readAll();
    final sessionRows = await _sessionsStore.readAll();
    final segmentRows = await _segmentsStore.readAll();
    final orderRows = await _cafeOrdersStore.readAll();
    final billRows = await _billsStore.readAll();

    final customerIdMap = _migrateIds(customerRows, 'USER');
    final cafeItemIdMap = _migrateIds(cafeItemRows, 'ITEM');
    final sessionIdMap = _migrateIds(sessionRows, 'SESSION');
    final segmentIdMap = _migrateIds(segmentRows, 'SEGMENT');
    final orderIdMap = _migrateIds(orderRows, 'ORDER');

    _replaceReferences(sessionRows, 'customer_id', customerIdMap);
    _replaceReferences(billRows, 'customer_id', customerIdMap);

    _replaceReferences(orderRows, 'item_id', cafeItemIdMap);

    _replaceReferences(segmentRows, 'session_id', sessionIdMap);
    _replaceReferences(orderRows, 'session_id', sessionIdMap);
    _replaceReferences(billRows, 'session_id', sessionIdMap);

    if (customerIdMap.isNotEmpty) await _customersStore.writeAll(customerRows);
    if (cafeItemIdMap.isNotEmpty) await _cafeItemsStore.writeAll(cafeItemRows);
    if (sessionIdMap.isNotEmpty || customerIdMap.isNotEmpty) {
      await _sessionsStore.writeAll(sessionRows);
    }
    if (segmentIdMap.isNotEmpty || sessionIdMap.isNotEmpty) {
      await _segmentsStore.writeAll(segmentRows);
    }
    if (orderIdMap.isNotEmpty ||
        cafeItemIdMap.isNotEmpty ||
        sessionIdMap.isNotEmpty) {
      await _cafeOrdersStore.writeAll(orderRows);
    }
    if (customerIdMap.isNotEmpty || sessionIdMap.isNotEmpty) {
      await _billsStore.writeAll(billRows);
    }
  }

  Future<void> _normalizeDateFiles() async {
    await _rewriteDates(_customersStore, _customerDateColumns);
    await _rewriteDates(_sessionsStore, _sessionDateColumns);
    await _rewriteDates(_segmentsStore, _segmentDateColumns);
    await _rewriteDates(_cafeOrdersStore, _orderDateColumns);
    await _rewriteDates(_billsStore, _billDateColumns);
  }

  Future<void> _rewriteDates(
    ExcelFileStore store,
    Set<String> dateColumns,
  ) async {
    final rows = await store.readAll();
    if (rows.isEmpty) return;

    await store.writeAll(
      rows
          .map(
            (row) => _excelRow(
              _modelRow(row, dateColumns: dateColumns),
              dateColumns: dateColumns,
            ),
          )
          .toList(),
    );
  }

  Future<String> nextCustomerId() => _serialized(() async {
    await _ensureReady();
    final rows = await _customersStore.readAll();
    return _formatId(
      'USER',
      _nextNumber(rows.map((r) => '${r['id']}'), 'USER'),
    );
  });

  Future<String> nextCafeItemId() => _serialized(() async {
    await _ensureReady();
    final rows = await _cafeItemsStore.readAll();
    return _formatId(
      'ITEM',
      _nextNumber(rows.map((r) => '${r['id']}'), 'ITEM'),
    );
  });

  Future<String> nextSessionId() => _serialized(() async {
    await _ensureReady();
    final rows = await _sessionsStore.readAll();
    return _formatId(
      'SESSION',
      _nextNumber(rows.map((r) => '${r['id']}'), 'SESSION'),
    );
  });

  Future<String> nextSegmentId() => _serialized(() async {
    await _ensureReady();
    final rows = await _segmentsStore.readAll();
    return _formatId(
      'SEGMENT',
      _nextNumber(rows.map((r) => '${r['id']}'), 'SEGMENT'),
    );
  });

  Future<String> nextCafeOrderId() => _serialized(() async {
    await _ensureReady();
    final rows = await _cafeOrdersStore.readAll();
    return _formatId(
      'ORDER',
      _nextNumber(rows.map((r) => '${r['id']}'), 'ORDER'),
    );
  });

  // ── Customers ──

  Future<List<Customer>> getCustomers() => _serialized(() async {
    await _ensureReady();
    final rows = await _customersStore.readAll();
    return rows
        .map((row) => _modelRow(row, dateColumns: _customerDateColumns))
        .map(Customer.fromMap)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  Future<Customer?> getCustomer(String id) => _serialized(() async {
    await _ensureReady();
    final rows = await _customersStore.readAll();
    final row = rows.where((r) => r['id'] == id).firstOrNull;
    if (row == null) return null;
    return Customer.fromMap(_modelRow(row, dateColumns: _customerDateColumns));
  });

  Future<void> insertCustomer(Customer customer) => _serialized(() async {
    await _ensureReady();
    final rows = await _customersStore.readAll();
    rows.add(_excelRow(customer.toMap(), dateColumns: _customerDateColumns));
    await _customersStore.writeAll(rows);
  });

  Future<void> updateCustomer(Customer customer) => _serialized(() async {
    await _ensureReady();
    final rows = await _customersStore.readAll();
    final index = rows.indexWhere((r) => r['id'] == customer.id);
    if (index == -1) return;
    rows[index] = _excelRow(
      customer.toMap(),
      dateColumns: _customerDateColumns,
    );
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
    }).toList()..sort((a, b) {
      final c = a.category.compareTo(b.category);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
  });

  Future<void> insertCafeItem(CafeItem item) => _serialized(() async {
    await _ensureReady();
    final rows = await _cafeItemsStore.readAll();
    rows.add(_excelRow(item.toMap()));
    await _cafeItemsStore.writeAll(rows);
  });

  Future<void> updateCafeItem(CafeItem item) => _serialized(() async {
    await _ensureReady();
    final rows = await _cafeItemsStore.readAll();
    final index = rows.indexWhere((r) => r['id'] == item.id);
    if (index == -1) return;
    rows[index] = _excelRow(item.toMap());
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
    sessions.add(_excelRow(session.toMap(), dateColumns: _sessionDateColumns));
    await _sessionsStore.writeAll(sessions);

    if (session.segments.isNotEmpty) {
      final segments = await _segmentsStore.readAll();
      for (final segment in session.segments) {
        segments.add(
          _excelRow(segment.toMap(), dateColumns: _segmentDateColumns),
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
    sessions[index] = _excelRow(
      session.toMap(),
      dateColumns: _sessionDateColumns,
    );
    await _sessionsStore.writeAll(sessions);

    if (!session.isActive && session.endedAt != null) {
      await _upsertBill(session);
    }
  });

  Future<void> insertSegment(SessionSegment segment) => _serialized(() async {
    await _ensureReady();
    final rows = await _segmentsStore.readAll();
    rows.add(_excelRow(segment.toMap(), dateColumns: _segmentDateColumns));
    await _segmentsStore.writeAll(rows);
  });

  Future<void> updateSegment(SessionSegment segment) => _serialized(() async {
    await _ensureReady();
    final rows = await _segmentsStore.readAll();
    final index = rows.indexWhere((r) => r['id'] == segment.id);
    if (index == -1) return;
    rows[index] = _excelRow(segment.toMap(), dateColumns: _segmentDateColumns);
    await _segmentsStore.writeAll(rows);
  });

  Future<void> insertCafeOrder(CafeOrder order) => _serialized(() async {
    await _ensureReady();
    final rows = await _cafeOrdersStore.readAll();
    rows.add(_excelRow(order.toMap(), dateColumns: _orderDateColumns));
    await _cafeOrdersStore.writeAll(rows);
  });

  Future<void> updateCafeOrder(CafeOrder order) => _serialized(() async {
    await _ensureReady();
    final rows = await _cafeOrdersStore.readAll();
    final index = rows.indexWhere((r) => r['id'] == order.id);
    if (index == -1) return;
    rows[index] = _excelRow(order.toMap(), dateColumns: _orderDateColumns);
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
    final map = _modelRow(row, dateColumns: _orderDateColumns);
    map['quantity'] = _asInt(map['quantity']);
    map['unit_price'] = _asInt(map['unit_price']);
    return CafeOrder.fromMap(map);
  });

  Future<List<GameSession>> getAllSessions() => _serialized(() async {
    await _ensureReady();
    final rows = await _sessionsStore.readAll();
    final sessions = <GameSession>[];
    for (final row in rows) {
      sessions.add(await _loadSessionDetails(_sessionFromRow(row)));
    }
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  });

  Future<List<CafeOrder>> getAllCafeOrders() => _serialized(() async {
    await _ensureReady();
    final rows = await _cafeOrdersStore.readAll();
    return rows
        .map((row) => _modelRow(row, dateColumns: _orderDateColumns))
        .map((map) {
          map['quantity'] = _asInt(map['quantity']);
          map['unit_price'] = _asInt(map['unit_price']);
          return CafeOrder.fromMap(map);
        })
        .toList();
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
          if (parseFlexibleDateTime(endedAt).isBefore(since)) continue;
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

    final segments =
        segmentRows
            .where((r) => r['session_id'] == session.id)
            .map((row) => _modelRow(row, dateColumns: _segmentDateColumns))
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

    final cafeOrders =
        orderRows
            .where((r) => r['session_id'] == session.id)
            .map((row) => _modelRow(row, dateColumns: _orderDateColumns))
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

    final customerRows = await _customersStore.readAll();
    final customerRow = customerRows
        .where((r) => r['id'] == loaded.customerId)
        .firstOrNull;
    final customerName = customerRow != null
        ? Customer.fromMap(
            _modelRow(customerRow, dateColumns: _customerDateColumns),
          ).fullName
        : 'نامشخص';

    final bill = {
      'session_id': loaded.id,
      'customer_id': loaded.customerId,
      'customer_name': customerName,
      'gaming_cost': '${loaded.gamingCost}',
      'cafe_cost': '${loaded.cafeCost}',
      'total_cost': '${loaded.totalCost}',
      'started_at': loaded.createdAt,
      'ended_at': loaded.endedAt,
    };

    final rows = await _billsStore.readAll();
    final index = rows.indexWhere((r) => r['session_id'] == loaded.id);
    if (index == -1) {
      rows.add(_excelRow(bill, dateColumns: _billDateColumns));
    } else {
      rows[index] = _excelRow(bill, dateColumns: _billDateColumns);
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

  Future<List<String>> getDataDirectoryPaths() async {
    await _ensureReady();
    return ExcelDataPaths.dataDirectories();
  }

  Future<String> getDataDirectoryPath() async {
    final paths = await getDataDirectoryPaths();
    return paths.first;
  }

  /// فقط برای تست
  void resetForTest() {
    _ready = false;
    _initFuture = null;
    _operationChain = Future<void>.value();
  }
}
