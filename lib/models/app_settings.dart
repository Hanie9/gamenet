class AppSettings {
  const AppSettings({
    this.hourlyRate1 = 50000,
    this.hourlyRate2 = 80000,
    this.hourlyRate3 = 100000,
    this.hourlyRate4 = 120000,
    this.currencyLabel = 'تومان',
  });

  final int hourlyRate1;
  final int hourlyRate2;
  final int hourlyRate3;
  final int hourlyRate4;
  final String currencyLabel;

  int rateForPlayers(int playerCount) {
    return switch (playerCount.clamp(1, 4)) {
      1 => hourlyRate1,
      2 => hourlyRate2,
      3 => hourlyRate3,
      _ => hourlyRate4,
    };
  }

  AppSettings copyWith({
    int? hourlyRate1,
    int? hourlyRate2,
    int? hourlyRate3,
    int? hourlyRate4,
    String? currencyLabel,
  }) {
    return AppSettings(
      hourlyRate1: hourlyRate1 ?? this.hourlyRate1,
      hourlyRate2: hourlyRate2 ?? this.hourlyRate2,
      hourlyRate3: hourlyRate3 ?? this.hourlyRate3,
      hourlyRate4: hourlyRate4 ?? this.hourlyRate4,
      currencyLabel: currencyLabel ?? this.currencyLabel,
    );
  }

  Map<String, dynamic> toMap() => {
        'hourly_rate_1': hourlyRate1,
        'hourly_rate_2': hourlyRate2,
        'hourly_rate_3': hourlyRate3,
        'hourly_rate_4': hourlyRate4,
        'currency_label': currencyLabel,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        hourlyRate1: map['hourly_rate_1'] as int? ?? 50000,
        hourlyRate2: map['hourly_rate_2'] as int? ?? 80000,
        hourlyRate3: map['hourly_rate_3'] as int? ?? 100000,
        hourlyRate4: map['hourly_rate_4'] as int? ?? 120000,
        currencyLabel: map['currency_label'] as String? ?? 'تومان',
      );
}
