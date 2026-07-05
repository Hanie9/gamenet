DateTime startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime endOfDay(DateTime date) =>
    startOfDay(date).add(const Duration(days: 1));

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
