import '../core/utils/date_utils.dart';

/// هر بخش زمانی بازی — برای تغییر تعداد بازیکن (مثلاً ۲ نفره به ۴ نفره یا برعکس)
class SessionSegment {
  const SessionSegment({
    required this.id,
    required this.sessionId,
    required this.playerCount,
    required this.hourlyRate,
    required this.startTime,
    this.endTime,
  });

  final String id;
  final String sessionId;
  final int playerCount;
  final int hourlyRate;
  final DateTime startTime;
  final DateTime? endTime;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  int get cost {
    final minutes = duration.inSeconds / 60.0;
    return (minutes / 60.0 * hourlyRate).round();
  }

  /// هزینه بخشی از این تایمر که در روز مشخص بوده
  int costForDay(DateTime day, {DateTime? now}) {
    final dayStart = startOfDay(day);
    final dayEnd = endOfDay(day);
    final segEnd = endTime ?? now ?? DateTime.now();

    if (segEnd.isBefore(dayStart) || !startTime.isBefore(segEnd)) {
      return 0;
    }
    if (startTime.isAfter(dayEnd) || !startTime.isBefore(dayEnd)) {
      return 0;
    }

    final overlapStart = startTime.isAfter(dayStart) ? startTime : dayStart;
    final overlapEnd = segEnd.isBefore(dayEnd) ? segEnd : dayEnd;

    if (!overlapStart.isBefore(overlapEnd)) return 0;

    final minutes = overlapEnd.difference(overlapStart).inSeconds / 60.0;
    return (minutes / 60.0 * hourlyRate).round();
  }

  /// مدت زمان این بخش که در بازه مشخص بوده
  Duration durationForRange(
    DateTime rangeStart,
    DateTime rangeEnd, {
    DateTime? now,
  }) {
    final segEnd = endTime ?? now ?? DateTime.now();
    if (segEnd.isBefore(rangeStart) || !startTime.isBefore(segEnd)) {
      return Duration.zero;
    }
    if (startTime.isAfter(rangeEnd)) return Duration.zero;

    final overlapStart = startTime.isAfter(rangeStart) ? startTime : rangeStart;
    final overlapEnd = segEnd.isBefore(rangeEnd) ? segEnd : rangeEnd;
    if (!overlapStart.isBefore(overlapEnd)) return Duration.zero;
    return overlapEnd.difference(overlapStart);
  }

  /// هزینه بخشی از این تایمر که در بازه مشخص بوده
  int costForRange(
    DateTime rangeStart,
    DateTime rangeEnd, {
    DateTime? now,
  }) {
    final seconds = durationForRange(rangeStart, rangeEnd, now: now).inSeconds;
    if (seconds <= 0) return 0;
    final minutes = seconds / 60.0;
    return (minutes / 60.0 * hourlyRate).round();
  }

  SessionSegment copyWith({DateTime? endTime}) {
    return SessionSegment(
      id: id,
      sessionId: sessionId,
      playerCount: playerCount,
      hourlyRate: hourlyRate,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'player_count': playerCount,
        'hourly_rate': hourlyRate,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
      };

  factory SessionSegment.fromMap(Map<String, dynamic> map) => SessionSegment(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        playerCount: map['player_count'] as int,
        hourlyRate: map['hourly_rate'] as int,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
      );
}
