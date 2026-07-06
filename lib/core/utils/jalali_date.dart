class JalaliDate {
  const JalaliDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;
}

String formatJalaliDateTime(DateTime value) {
  final local = value.toLocal();
  final jalali = gregorianToJalali(local.year, local.month, local.day);
  return '${_two(jalali.year)}/${_two(jalali.month)}/${_two(jalali.day)} '
      '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
}

DateTime parseFlexibleDateTime(String value) {
  final normalized = _toEnglishDigits(value.trim());
  if (normalized.isEmpty) {
    throw FormatException('تاریخ خالی است.');
  }

  if (normalized.contains('T') || normalized.contains('-')) {
    return DateTime.parse(normalized);
  }

  final parts = normalized.split(RegExp(r'\s+'));
  final dateParts = parts.first.split('/');
  if (dateParts.length != 3) {
    throw FormatException('فرمت تاریخ نامعتبر است: $value');
  }

  final timeParts = parts.length > 1 ? parts[1].split(':') : const ['0', '0', '0'];
  final jalali = JalaliDate(
    int.parse(dateParts[0]),
    int.parse(dateParts[1]),
    int.parse(dateParts[2]),
  );
  final gregorian = jalaliToGregorian(jalali.year, jalali.month, jalali.day);
  return DateTime(
    gregorian.year,
    gregorian.month,
    gregorian.day,
    int.parse(timeParts[0]),
    timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
    timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
  );
}

JalaliDate gregorianToJalali(int gy, int gm, int gd) {
  final gDaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  final jDaysInMonth = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];

  gy -= 1600;
  gm -= 1;
  gd -= 1;

  var gDayNo =
      365 * gy + ((gy + 3) ~/ 4) - ((gy + 99) ~/ 100) + ((gy + 399) ~/ 400);
  for (var i = 0; i < gm; ++i) {
    gDayNo += gDaysInMonth[i];
  }
  if (gm > 1 &&
      ((gy + 1600) % 4 == 0 &&
          ((gy + 1600) % 100 != 0 || (gy + 1600) % 400 == 0))) {
    gDayNo++;
  }
  gDayNo += gd;

  var jDayNo = gDayNo - 79;
  final jNp = jDayNo ~/ 12053;
  jDayNo %= 12053;

  var jy = 979 + 33 * jNp + 4 * (jDayNo ~/ 1461);
  jDayNo %= 1461;

  if (jDayNo >= 366) {
    jy += (jDayNo - 1) ~/ 365;
    jDayNo = (jDayNo - 1) % 365;
  }

  var jm = 0;
  while (jm < 11 && jDayNo >= jDaysInMonth[jm]) {
    jDayNo -= jDaysInMonth[jm];
    jm++;
  }

  return JalaliDate(jy, jm + 1, jDayNo + 1);
}

JalaliDate jalaliToGregorian(int jy, int jm, int jd) {
  final gDaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  final jDaysInMonth = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];

  jy -= 979;
  jm -= 1;
  jd -= 1;

  var jDayNo = 365 * jy + (jy ~/ 33) * 8 + (((jy % 33) + 3) ~/ 4);
  for (var i = 0; i < jm; ++i) {
    jDayNo += jDaysInMonth[i];
  }
  jDayNo += jd;

  var gDayNo = jDayNo + 79;
  var gy = 1600 + 400 * (gDayNo ~/ 146097);
  gDayNo %= 146097;

  var leap = true;
  if (gDayNo >= 36525) {
    gDayNo--;
    gy += 100 * (gDayNo ~/ 36524);
    gDayNo %= 36524;
    if (gDayNo >= 365) {
      gDayNo++;
    } else {
      leap = false;
    }
  }

  gy += 4 * (gDayNo ~/ 1461);
  gDayNo %= 1461;

  if (gDayNo >= 366) {
    leap = false;
    gDayNo--;
    gy += gDayNo ~/ 365;
    gDayNo %= 365;
  }

  var gm = 0;
  while (gDayNo >= gDaysInMonth[gm] + (gm == 1 && leap ? 1 : 0)) {
    gDayNo -= gDaysInMonth[gm] + (gm == 1 && leap ? 1 : 0);
    gm++;
  }

  return JalaliDate(gy, gm + 1, gDayNo + 1);
}

String _two(int value) => value.toString().padLeft(2, '0');

const jalaliMonthNames = <String>[
  '',
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

JalaliDate gregorianToJalaliDate(DateTime value) {
  final local = value.toLocal();
  return gregorianToJalali(local.year, local.month, local.day);
}

String jalaliMonthName(int month) {
  if (month < 1 || month > 12) {
    throw RangeError.range(month, 1, 12, 'month');
  }
  return jalaliMonthNames[month];
}

String monthlyReportFileName(int jalaliYear, int jalaliMonth) =>
    '${jalaliMonthName(jalaliMonth)}-$jalaliYear.xlsx';

/// شروع ماه شمسی (۰۰:۰۰:۰۰ محلی)
DateTime jalaliMonthStart(int jalaliYear, int jalaliMonth) {
  final gregorian = jalaliToGregorian(jalaliYear, jalaliMonth, 1);
  return DateTime(gregorian.year, gregorian.month, gregorian.day);
}

/// پایان ماه شمسی (۲۳:۵۹:۵۹.۹۹۹ محلی)
DateTime jalaliMonthEnd(int jalaliYear, int jalaliMonth) {
  final nextMonthStart = jalaliMonth == 12
      ? jalaliMonthStart(jalaliYear + 1, 1)
      : jalaliMonthStart(jalaliYear, jalaliMonth + 1);
  return nextMonthStart.subtract(const Duration(milliseconds: 1));
}

bool isInJalaliMonth(DateTime value, int jalaliYear, int jalaliMonth) {
  final jalali = gregorianToJalaliDate(value);
  return jalali.year == jalaliYear && jalali.month == jalaliMonth;
}

/// آخرین ماه شمسی کامل (ماه قبل از ماه جاری)
({int year, int month}) lastCompletedJalaliMonth([DateTime? now]) {
  final current = gregorianToJalaliDate(now ?? DateTime.now());
  var year = current.year;
  var month = current.month - 1;
  if (month < 1) {
    month = 12;
    year--;
  }
  return (year: year, month: month);
}

/// همه ماه‌های شمسی از [start] تا [end] (شامل هر دو)
Iterable<({int year, int month})> jalaliMonthsBetween(
  ({int year, int month}) start,
  ({int year, int month}) end,
) sync* {
  var year = start.year;
  var month = start.month;
  while (year < end.year || (year == end.year && month <= end.month)) {
    yield (year: year, month: month);
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
  }
}

String _toEnglishDigits(String value) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var result = value;
  for (var i = 0; i < 10; i++) {
    result = result.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
  }
  return result;
}
