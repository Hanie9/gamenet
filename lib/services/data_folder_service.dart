import 'dart:io';

import 'excel/excel_data_paths.dart';

class DataFolderService {
  const DataFolderService._();

  static Future<String> getPath() => ExcelDataPaths.documentsDirectory();

  static Future<List<String>> getPaths() => ExcelDataPaths.dataDirectories();

  static Future<void> openInFileManager({int index = 0}) async {
    final dirs = await ExcelDataPaths.ensureDataDirectories();
    if (dirs.isEmpty) return;
    final dir = dirs[index.clamp(0, dirs.length - 1)];
    await _openPath(dir);
  }

  static Future<void> openAllInFileManager() async {
    final dirs = await ExcelDataPaths.ensureDataDirectories();
    for (final dir in dirs) {
      await _openPath(dir);
    }
  }

  static Future<void> _openPath(String dir) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [dir]);
      return;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [dir]);
      return;
    }
    if (Platform.isMacOS) {
      await Process.run('open', [dir]);
    }
  }

  static const dataFiles = [
    ExcelDataPaths.customersFile,
    ExcelDataPaths.cafeItemsFile,
    ExcelDataPaths.sessionsFile,
    ExcelDataPaths.segmentsFile,
    ExcelDataPaths.cafeOrdersFile,
    ExcelDataPaths.billsFile,
    ExcelDataPaths.settingsFile,
  ];
}
