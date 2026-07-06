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

  static Future<String> documentsDirectory() async {
    if (testOverride != null) return testOverride!;

    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      final base = userProfile != null
          ? p.join(userProfile, 'Documents')
          : Directory.current.path;
      return p.join(base, appFolderName);
    }

    final home = Platform.environment['HOME'] ?? Directory.current.path;
    return p.join(home, 'Documents', appFolderName);
  }

  static Future<String> ensureDataDirectory() async {
    final dir = await documentsDirectory();
    await Directory(dir).create(recursive: true);
    return dir;
  }

  static Future<String> filePath(String fileName) async {
    final dir = await ensureDataDirectory();
    return p.join(dir, fileName);
  }
}
