import 'dart:io';

import 'excel/excel_data_paths.dart';

class DataFolderService {
  const DataFolderService._();

  static Future<String> getPath() => ExcelDataPaths.documentsDirectory();

  static Future<void> openInFileManager() async {
    final dir = await ExcelDataPaths.ensureDataDirectory();
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
