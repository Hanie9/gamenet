import 'cafe_order.dart';
import '../core/utils/date_utils.dart';
import 'service_type.dart';
import 'session_segment.dart';

enum SessionStatus { active, ended }

class GameSession {
  const GameSession({
    required this.id,
    required this.customerId,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.segments = const [],
    this.cafeOrders = const [],
  });

  final String id;
  final String customerId;
  final ServiceType serviceType;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime? endedAt;
  final List<SessionSegment> segments;
  final List<CafeOrder> cafeOrders;

  bool get isActive => status == SessionStatus.active;

  SessionSegment? get activeSegment {
    if (!isActive) return null;
    return segments.where((s) => s.endTime == null).firstOrNull;
  }

  int get currentPlayerCount => activeSegment?.playerCount ?? 0;

  bool get hasActiveGaming => activeSegment != null;

  bool get isCafeOnly => isActive && !hasActiveGaming;

  int get gamingCost =>
      segments.fold(0, (sum, segment) => sum + segment.cost);

  int get cafeCost =>
      cafeOrders.fold(0, (sum, order) => sum + order.totalPrice);

  int get totalCost => gamingCost + cafeCost;

  /// درآمد قابل‌محاسبه برای یک روز مشخص (بازی + کافه)
  int revenueForDay(DateTime day, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    final gaming = segments.fold(
      0,
      (sum, segment) => sum + segment.costForDay(day, now: effectiveNow),
    );
    final cafe = cafeOrders
        .where((order) => isSameDay(order.createdAt, day))
        .fold(0, (sum, order) => sum + order.totalPrice);
    return gaming + cafe;
  }

  Duration get totalDuration =>
      segments.fold(Duration.zero, (sum, s) => sum + s.duration);

  GameSession copyWith({
    ServiceType? serviceType,
    SessionStatus? status,
    DateTime? endedAt,
    List<SessionSegment>? segments,
    List<CafeOrder>? cafeOrders,
  }) {
    return GameSession(
      id: id,
      customerId: customerId,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      createdAt: createdAt,
      endedAt: endedAt ?? this.endedAt,
      segments: segments ?? this.segments,
      cafeOrders: cafeOrders ?? this.cafeOrders,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'service_type': serviceType.id,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
      };

  factory GameSession.fromMap(Map<String, dynamic> map) => GameSession(
        id: map['id'] as String,
        customerId: map['customer_id'] as String,
        serviceType: ServiceType.fromId(map['service_type'] as String),
        status: SessionStatus.values.byName(map['status'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        endedAt: map['ended_at'] != null
            ? DateTime.parse(map['ended_at'] as String)
            : null,
      );
}
