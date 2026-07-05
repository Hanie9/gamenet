import 'package:intl/intl.dart';

NumberFormat? _currencyFormatCache;

NumberFormat get _currencyFormat =>
    _currencyFormatCache ??= NumberFormat('#,###', 'fa_IR');

String formatCurrency(int amount, {String suffix = 'تومان'}) {
  return '${_currencyFormat.format(amount)} $suffix';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime dt) {
  return DateFormat('yyyy/MM/dd - HH:mm', 'fa_IR').format(dt);
}

String toPersianDigits(String input) {
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  return input.replaceAllMapped(RegExp(r'[0-9]'), (m) => persian[int.parse(m[0]!)]);
}
