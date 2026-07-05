import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/app_settings.dart';
import '../models/cafe_item.dart';
import '../models/cafe_order.dart';
import '../models/customer.dart';
import '../models/game_session.dart';
import '../models/session_segment.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'gamenet.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            phone TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE cafe_items (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            price INTEGER NOT NULL,
            category TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE game_sessions (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            service_type TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            ended_at TEXT,
            FOREIGN KEY (customer_id) REFERENCES customers(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE session_segments (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            player_count INTEGER NOT NULL,
            hourly_rate INTEGER NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT,
            FOREIGN KEY (session_id) REFERENCES game_sessions(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE cafe_orders (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            item_id TEXT NOT NULL,
            item_name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES game_sessions(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            hourly_rate_1 INTEGER NOT NULL,
            hourly_rate_2 INTEGER NOT NULL,
            hourly_rate_3 INTEGER NOT NULL,
            hourly_rate_4 INTEGER NOT NULL,
            currency_label TEXT NOT NULL
          )
        ''');

        await db.insert('settings', {
          'id': 1,
          ...const AppSettings().toMap(),
        });

        await _seedCafeItems(db);
      },
    );
  }

  Future<void> _seedCafeItems(Database db) async {
    final items = [
      {'id': 'c1', 'name': 'چای', 'price': 25000, 'category': 'نوشیدنی'},
      {'id': 'c2', 'name': 'قهوه', 'price': 45000, 'category': 'نوشیدنی'},
      {'id': 'c3', 'name': 'آب معدنی', 'price': 15000, 'category': 'نوشیدنی'},
      {'id': 'c4', 'name': 'نوشابه', 'price': 30000, 'category': 'نوشیدنی'},
      {'id': 'c5', 'name': 'چیپس', 'price': 35000, 'category': 'تنقلات'},
      {'id': 'c6', 'name': 'پفک', 'price': 30000, 'category': 'تنقلات'},
      {'id': 'c7', 'name': 'ساندویچ', 'price': 85000, 'category': 'غذا'},
      {'id': 'c8', 'name': 'پیتزا', 'price': 120000, 'category': 'غذا'},
    ];

    for (final item in items) {
      await db.insert('cafe_items', {
        ...item,
        'is_active': 1,
      });
    }
  }

  // ── Customers ──

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final rows = await db.query('customers', orderBy: 'created_at DESC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    final db = await database;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ── Cafe Items ──

  Future<List<CafeItem>> getCafeItems() async {
    final db = await database;
    final rows = await db.query('cafe_items', orderBy: 'category, name');
    return rows.map(CafeItem.fromMap).toList();
  }

  Future<void> insertCafeItem(CafeItem item) async {
    final db = await database;
    await db.insert('cafe_items', item.toMap());
  }

  Future<void> updateCafeItem(CafeItem item) async {
    final db = await database;
    await db.update(
      'cafe_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteCafeItem(String id) async {
    final db = await database;
    await db.delete('cafe_items', where: 'id = ?', whereArgs: [id]);
  }

  // ── Sessions ──

  Future<void> insertSession(GameSession session) async {
    final db = await database;
    await db.insert('game_sessions', session.toMap());
    for (final segment in session.segments) {
      await db.insert('session_segments', segment.toMap());
    }
  }

  Future<void> updateSession(GameSession session) async {
    final db = await database;
    await db.update(
      'game_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> insertSegment(SessionSegment segment) async {
    final db = await database;
    await db.insert('session_segments', segment.toMap());
  }

  Future<void> updateSegment(SessionSegment segment) async {
    final db = await database;
    await db.update(
      'session_segments',
      segment.toMap(),
      where: 'id = ?',
      whereArgs: [segment.id],
    );
  }

  Future<void> insertCafeOrder(CafeOrder order) async {
    final db = await database;
    await db.insert('cafe_orders', order.toMap());
  }

  Future<void> updateCafeOrder(CafeOrder order) async {
    final db = await database;
    await db.update(
      'cafe_orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> deleteCafeOrder(String id) async {
    final db = await database;
    await db.delete('cafe_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<CafeOrder?> getCafeOrder(String id) async {
    final db = await database;
    final rows =
        await db.query('cafe_orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return CafeOrder.fromMap(rows.first);
  }

  Future<List<GameSession>> getSessionsForCustomer(String customerId) async {
    final db = await database;
    final rows = await db.query(
      'game_sessions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );

    final sessions = <GameSession>[];
    for (final row in rows) {
      sessions.add(await _loadSessionDetails(GameSession.fromMap(row)));
    }
    return sessions;
  }

  Future<List<GameSession>> getActiveSessions() async {
    final db = await database;
    final rows = await db.query(
      'game_sessions',
      where: "status = 'active'",
      orderBy: 'created_at DESC',
    );

    final sessions = <GameSession>[];
    for (final row in rows) {
      sessions.add(await _loadSessionDetails(GameSession.fromMap(row)));
    }
    return sessions;
  }

  Future<List<GameSession>> getSessionsEndedSince(DateTime since) async {
    final db = await database;
    final rows = await db.query(
      'game_sessions',
      where: "status = 'ended' AND ended_at >= ?",
      whereArgs: [since.toIso8601String()],
      orderBy: 'ended_at DESC',
    );

    final sessions = <GameSession>[];
    for (final row in rows) {
      sessions.add(await _loadSessionDetails(GameSession.fromMap(row)));
    }
    return sessions;
  }

  Future<GameSession?> getSession(String id) async {
    final db = await database;
    final rows =
        await db.query('game_sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _loadSessionDetails(GameSession.fromMap(rows.first));
  }

  Future<GameSession> _loadSessionDetails(GameSession session) async {
    final db = await database;

    final segmentRows = await db.query(
      'session_segments',
      where: 'session_id = ?',
      whereArgs: [session.id],
      orderBy: 'start_time ASC',
    );

    final orderRows = await db.query(
      'cafe_orders',
      where: 'session_id = ?',
      whereArgs: [session.id],
      orderBy: 'created_at ASC',
    );

    return session.copyWith(
      segments: segmentRows.map(SessionSegment.fromMap).toList(),
      cafeOrders: orderRows.map(CafeOrder.fromMap).toList(),
    );
  }

  // ── Settings ──

  Future<AppSettings> getSettings() async {
    final db = await database;
    final rows = await db.query('settings', where: 'id = 1');
    if (rows.isEmpty) return const AppSettings();
    return AppSettings.fromMap(rows.first);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    await db.update(
      'settings',
      settings.toMap(),
      where: 'id = 1',
    );
  }
}
