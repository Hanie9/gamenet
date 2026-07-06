import 'dart:io';

import 'package:path/path.dart' as p;

/// مسیر ذخیره فایل‌های اکسل اپ در Documents/201
class ExcelDataPaths {
  ExcelDataPaths._();

  static const appFolderName = '201';

  /// فقط برای تست — مسیر موقت
  static String? testOverride;

  static const customersFile = 'مشتریان.xlsx';
  static const cafeItemsFile = 'آیتم‌های_کافه.xlsx';
  static const sessionsFile = 'جلسات.xlsx';
  static const segmentsFile = 'بخش‌های_بازی.xlsx';
  static const cafeOrdersFile = 'سفارش‌های_کافه.xlsx';
  static const billsFile = 'صورتحساب‌ها.xlsx';
  static const settingsFile = 'تنظیمات.xlsx';

  /// مسیر اصلی (برای نمایش در UI)
  static Future<String> documentsDirectory() async {
    final dirs = await dataDirectories();
    return dirs.first;
  }

  /// همه مسیرهای ذخیره — روی ویندوز: C و D (در صورت وجود)
  static Future<List<String>> dataDirectories() async {
    if (testOverride != null) return [testOverride!];

    if (Platform.isWindows) {
      final dirs = <String>[];

      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        dirs.add(p.join(userProfile, 'Documents', appFolderName));
      }

      if (_driveExists('D')) {
        dirs.add(p.join('D:', 'Documents', appFolderName));
      }

      if (dirs.isEmpty) {
        dirs.add(p.join(Directory.current.path, appFolderName));
      }
      return dirs;
    }

    final home = Platform.environment['HOME'] ?? Directory.current.path;
    return [p.join(home, 'Documents', appFolderName)];
  }

  static bool _driveExists(String letter) {
    try {
      return Directory('$letter:\\').existsSync();
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> ensureDataDirectories() async {
    final dirs = await dataDirectories();
    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }
    return dirs;
  }

  static Future<String> ensureDataDirectory() async {
    final dirs = await ensureDataDirectories();
    return dirs.first;
  }

  static Future<String> filePath(String fileName) async {
    final dir = await ensureDataDirectory();
    return p.join(dir, fileName);
  }
}
