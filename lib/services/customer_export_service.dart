import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/customer.dart';

class CustomerExportService {
  const CustomerExportService._();

  /// ساخت فایل اکسل مشتریان و باز کردن پنجره ذخیره
  /// در صورت لغو توسط کاربر مقدار null برمی‌گرداند، در غیر این صورت مسیر فایل.
  static Future<String?> exportToExcel(List<Customer> customers) async {
    debugPrint('[ExcelExport] start, customers=${customers.length}');

    late final Uint8List bytes;
    try {
      bytes = buildExcelBytes(customers);
      debugPrint('[ExcelExport] bytes built: ${bytes.length}');
    } catch (e, stack) {
      debugPrint('[ExcelExport] build failed: $e');
      debugPrint('$stack');
      rethrow;
    }

    final now = DateTime.now();
    final stamp =
        '${now.year}-${_two(now.month)}-${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';

    String savePath;
    try {
      debugPrint('[ExcelExport] opening save dialog...');
      final location = await getSaveLocation(
        suggestedName: 'customers_$stamp.xlsx',
      );
      debugPrint('[ExcelExport] dialog result: ${location?.path}');

      if (location == null) return null;

      savePath = location.path;
      if (!savePath.toLowerCase().endsWith('.xlsx')) {
        savePath = '$savePath.xlsx';
      }
    } catch (e, stack) {
      debugPrint('[ExcelExport] save dialog failed: $e');
      debugPrint('$stack');
      savePath = _fallbackSavePath(stamp);
      debugPrint('[ExcelExport] using fallback path: $savePath');
    }

    try {
      debugPrint('[ExcelExport] writing file: $savePath');
      await File(savePath).writeAsBytes(bytes, flush: true);
      final normalized = p.normalize(savePath);
      debugPrint('[ExcelExport] success: $normalized');
      return normalized;
    } catch (e, stack) {
      debugPrint('[ExcelExport] write failed: $e');
      debugPrint('$stack');
      rethrow;
    }
  }

  static Uint8List buildExcelBytes(List<Customer> customers) {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet();
    if (defaultSheetName == null) {
      throw StateError('برگه اکسل ساخته نشد.');
    }

    const sheetTitle = 'Sheet1';
    final dataSheet = excel[sheetTitle];

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    const headers = ['ردیف', 'نام', 'نام خانوادگی', 'شماره تلفن'];
    dataSheet.setRowHeight(0, 22);
    for (var col = 0; col < headers.length; col++) {
      _setCell(
        dataSheet,
        col: col,
        row: 0,
        value: TextCellValue(headers[col]),
        style: headerStyle,
      );
    }

    for (var i = 0; i < customers.length; i++) {
      final customer = customers[i];
      final row = i + 1;
      dataSheet.setRowHeight(row, 20);
      _setCell(
        dataSheet,
        col: 0,
        row: row,
        value: IntCellValue(i + 1),
        style: dataStyle,
      );
      _setCell(
        dataSheet,
        col: 1,
        row: row,
        value: TextCellValue(customer.firstName),
        style: dataStyle,
      );
      _setCell(
        dataSheet,
        col: 2,
        row: row,
        value: TextCellValue(customer.lastName),
        style: dataStyle,
      );
      _setCell(
        dataSheet,
        col: 3,
        row: row,
        value: TextCellValue(customer.phone),
        style: dataStyle,
      );
    }

    const columnWidths = [10.0, 18.0, 18.0, 22.0];
    for (var col = 0; col < headers.length; col++) {
      dataSheet.setColumnWidth(col, columnWidths[col]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('ساخت محتوای فایل اکسل ناموفق بود.');
    }

    return Uint8List.fromList(encoded);
  }

  static void _setCell(
    Sheet sheet, {
    required int col,
    required int row,
    required CellValue value,
    required CellStyle style,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    cell.cellStyle = style;
  }

  static String _fallbackSavePath(String stamp) {
    final fileName = 'customers_$stamp.xlsx';

    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      final dir = userProfile != null
          ? p.join(userProfile, 'Documents')
          : Directory.current.path;
      Directory(dir).createSync(recursive: true);
      return p.join(dir, fileName);
    }

    final home = Platform.environment['HOME'] ?? Directory.current.path;
    final dir = p.join(home, 'Documents');
    Directory(dir).createSync(recursive: true);
    return p.join(dir, fileName);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
