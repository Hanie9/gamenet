import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/cafe_item.dart';
import '../models/cafe_order.dart';
import '../models/customer.dart';
import '../models/game_session.dart';
import '../models/service_type.dart';
import '../models/session_segment.dart';
import 'database_service.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  final _db = DatabaseService.instance;
  final _uuid = const Uuid();

  bool _loading = true;
  List<Customer> _customers = [];
  List<CafeItem> _cafeItems = [];
  List<GameSession> _activeSessions = [];
  List<GameSession> _endedSessionsToday = [];
  AppSettings _settings = const AppSettings();
  String? _selectedCustomerId;

  bool get loading => _loading;
  List<Customer> get customers => _customers;
  List<CafeItem> get cafeItems => _cafeItems;
  List<CafeItem> get activeCafeItems =>
      _cafeItems.where((i) => i.isActive).toList();
  List<GameSession> get activeSessions => _activeSessions;

  /// جلساتی که تایمر بازی فعال دارند
  List<GameSession> get gamingActiveSessions =>
      _activeSessions.where((s) => s.hasActiveGaming).toList();

  /// درآمد واقعی امروز (بازی + کافه) بر اساس زمان و تاریخ
  int get todayRevenue {
    final now = DateTime.now();
    final today = now;
    final seen = <String>{};
    var total = 0;

    for (final session in _activeSessions) {
      seen.add(session.id);
      total += session.revenueForDay(today, now: now);
    }
    for (final session in _endedSessionsToday) {
      if (seen.contains(session.id)) continue;
      total += session.revenueForDay(today, now: now);
    }
    return total;
  }

  AppSettings get settings => _settings;
  String? get selectedCustomerId => _selectedCustomerId;

  Customer? get selectedCustomer {
    if (_selectedCustomerId == null) return null;
    return _customers
        .where((c) => c.id == _selectedCustomerId)
        .firstOrNull;
  }

  GameSession? sessionForCustomer(String customerId) {
    return _activeSessions
        .where((s) => s.customerId == customerId)
        .firstOrNull;
  }

  Future<void> _init() async {
    await refresh();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _customers = await _db.getCustomers();
    _cafeItems = await _db.getCafeItems();
    _activeSessions = await _db.getActiveSessions();
    final todayStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    _endedSessionsToday = await _db.getSessionsEndedSince(todayStart);
    _settings = await _db.getSettings();
    notifyListeners();
  }

  void selectCustomer(String? id) {
    _selectedCustomerId = id;
    notifyListeners();
  }

  // ── Customers ──

  Future<Customer> addCustomer({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final customer = Customer(
      id: _uuid.v4(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      phone: phone.trim(),
      createdAt: DateTime.now(),
    );
    await _db.insertCustomer(customer);
    await refresh();
    return customer;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.updateCustomer(customer);
    await refresh();
  }

  Future<void> deleteCustomer(String id) async {
    final active = sessionForCustomer(id);
    if (active != null) {
      throw StateError('مشتری در حال بازی است. ابتدا بازی را پایان دهید.');
    }
    await _db.deleteCustomer(id);
    if (_selectedCustomerId == id) _selectedCustomerId = null;
    await refresh();
  }

  Future<List<GameSession>> getCustomerHistory(String customerId) async {
    return _db.getSessionsForCustomer(customerId);
  }

  // ── Cafe ──

  Future<void> addCafeItem({
    required String name,
    required int price,
    required String category,
  }) async {
    final item = CafeItem(
      id: _uuid.v4(),
      name: name.trim(),
      price: price,
      category: category.trim(),
    );
    await _db.insertCafeItem(item);
    await refresh();
  }

  Future<void> updateCafeItem(CafeItem item) async {
    await _db.updateCafeItem(item);
    await refresh();
  }

  Future<void> deleteCafeItem(String id) async {
    await _db.deleteCafeItem(id);
    await refresh();
  }

  Future<GameSession> getOrCreateActiveSessionForCustomer(
    String customerId,
  ) async {
    final existing = sessionForCustomer(customerId);
    if (existing != null) return existing;

    final session = GameSession(
      id: _uuid.v4(),
      customerId: customerId,
      serviceType: ServiceType.cafe,
      status: SessionStatus.active,
      createdAt: DateTime.now(),
    );
    await _db.insertSession(session);
    await refresh();
    final loaded = await _db.getSession(session.id);
    return loaded ?? session;
  }

  Future<void> orderCafeItemForCustomer({
    required String customerId,
    required CafeItem item,
    int quantity = 1,
  }) async {
    final session = await getOrCreateActiveSessionForCustomer(customerId);
    await orderCafeItem(
      sessionId: session.id,
      item: item,
      quantity: quantity,
    );
  }

  Future<void> orderCafeItem({
    required String sessionId,
    required CafeItem item,
    int quantity = 1,
  }) async {
    final session = await _db.getSession(sessionId);
    final existing = session?.cafeOrders
        .where((o) => o.itemId == item.id)
        .firstOrNull;

    if (existing != null) {
      await updateCafeOrderQuantity(
        existing.id,
        existing.quantity + quantity,
      );
      return;
    }

    final order = CafeOrder(
      id: _uuid.v4(),
      sessionId: sessionId,
      itemId: item.id,
      itemName: item.name,
      quantity: quantity,
      unitPrice: item.price,
      createdAt: DateTime.now(),
    );
    await _db.insertCafeOrder(order);
    await refresh();
  }

  Future<void> updateCafeOrderQuantity(String orderId, int quantity) async {
    if (quantity <= 0) {
      await _db.deleteCafeOrder(orderId);
    } else {
      final order = await _db.getCafeOrder(orderId);
      if (order == null) return;
      await _db.updateCafeOrder(order.copyWith(quantity: quantity));
    }
    await refresh();
  }

  Future<void> removeCafeOrder(String orderId) async {
    await _db.deleteCafeOrder(orderId);
    await refresh();
  }

  // ── Gaming ──

  Future<GameSession> startSession({
    required String customerId,
    required int playerCount,
    ServiceType serviceType = ServiceType.gaming,
  }) async {
    final existing = sessionForCustomer(customerId);
    if (existing != null) {
      if (existing.hasActiveGaming) {
        throw StateError('این مشتری در حال حاضر در حال بازی است.');
      }
      // جلسه کافه موجود — افزودن تایمر بازی به همان جلسه
      final segment = SessionSegment(
        id: _uuid.v4(),
        sessionId: existing.id,
        playerCount: playerCount,
        hourlyRate: _settings.rateForPlayers(playerCount),
        startTime: DateTime.now(),
      );
      await _db.insertSegment(segment);
      await _db.updateSession(
        existing.copyWith(serviceType: serviceType),
      );
      await refresh();
      final loaded = await _db.getSession(existing.id);
      return loaded ?? existing;
    }

    final sessionId = _uuid.v4();
    final segment = SessionSegment(
      id: _uuid.v4(),
      sessionId: sessionId,
      playerCount: playerCount,
      hourlyRate: _settings.rateForPlayers(playerCount),
      startTime: DateTime.now(),
    );

    final session = GameSession(
      id: sessionId,
      customerId: customerId,
      serviceType: serviceType,
      status: SessionStatus.active,
      createdAt: DateTime.now(),
      segments: [segment],
    );

    await _db.insertSession(session);
    await refresh();
    return session;
  }

  /// تغییر تعداد بازیکن — تایمر قبلی بسته و تایمر جدید شروع می‌شود
  Future<void> changePlayerCount({
    required String sessionId,
    required int newPlayerCount,
  }) async {
    final session = await _db.getSession(sessionId);
    if (session == null || !session.isActive) {
      throw StateError('جلسه بازی فعال یافت نشد.');
    }

    final active = session.activeSegment;
    if (active == null) throw StateError('بخش فعال بازی یافت نشد.');

    if (newPlayerCount < 1 || newPlayerCount > 4) {
      throw StateError('تعداد بازیکن باید بین ۱ تا ۴ باشد.');
    }

    if (newPlayerCount == active.playerCount) {
      throw StateError('تعداد بازیکن جدید با تعداد فعلی یکسان است.');
    }

    final now = DateTime.now();
    await _db.updateSegment(active.copyWith(endTime: now));

    final newSegment = SessionSegment(
      id: _uuid.v4(),
      sessionId: sessionId,
      playerCount: newPlayerCount,
      hourlyRate: _settings.rateForPlayers(newPlayerCount),
      startTime: now,
    );
    await _db.insertSegment(newSegment);
    await refresh();
  }

  Future<GameSession> endSession(String sessionId) async {
    final session = await _db.getSession(sessionId);
    if (session == null || !session.isActive) {
      throw StateError('جلسه بازی فعال یافت نشد.');
    }

    final now = DateTime.now();
    final active = session.activeSegment;
    if (active != null) {
      await _db.updateSegment(active.copyWith(endTime: now));
    }

    final ended = session.copyWith(
      status: SessionStatus.ended,
      endedAt: now,
    );
    await _db.updateSession(ended);
    await refresh();
    final updated = await _db.getSession(sessionId);
    return updated ?? ended;
  }

  // ── Settings ──

  Future<void> saveSettings(AppSettings settings) async {
    await _db.saveSettings(settings);
    _settings = settings;
    notifyListeners();
  }

  // ── Stats ──

  Future<String> get dataDirectoryPath => _db.getDataDirectoryPath();

  CustomerStats statsForCustomer(List<GameSession> sessions) {
    final ended = sessions.where((s) => !s.isActive).toList();
    return CustomerStats(
      totalGames: ended.length,
      totalPlayTime: ended.fold(
        Duration.zero,
        (sum, s) => sum + s.totalDuration,
      ),
      totalSpent: ended.fold(0, (sum, s) => sum + s.totalCost),
      totalBills: ended.length,
    );
  }
}

class CustomerStats {
  const CustomerStats({
    required this.totalGames,
    required this.totalPlayTime,
    required this.totalSpent,
    required this.totalBills,
  });

  final int totalGames;
  final Duration totalPlayTime;
  final int totalSpent;
  final int totalBills;
}
