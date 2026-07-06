import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';

/// خواندن و نوشتن یک جدول در فایل اکسل (ردیف اول = عنوان ستون‌ها)
class ExcelFileStore {
  ExcelFileStore({
    required this.filePath,
    required this.columns,
    required this.headers,
  }) : assert(columns.length == headers.length);

  final String filePath;
  final List<String> columns;
  final List<String> headers;

  Future<void> ensureExists() async {
    final file = File(filePath);
    if (await file.exists()) return;
    await writeAll(const []);
  }

  Future<List<Map<String, dynamic>>> readAll() async {
    final file = File(filePath);
    if (!await file.exists()) {
      await ensureExists();
      return [];
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return [];

    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final sheet = excel.tables.values.first;
    if (sheet == null || sheet.maxRows <= 1) return [];

    final rows = <Map<String, dynamic>>[];
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final map = <String, dynamic>{};
      var hasValue = false;

      for (var col = 0; col < columns.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
        );
        final text = _cellText(cell);
        if (text != null && text.isNotEmpty) {
          hasValue = true;
        }
        map[columns[col]] = text ?? '';
      }

      if (hasValue) {
        rows.add(map);
      }
    }

    return rows;
  }

  Future<void> writeAll(List<Map<String, dynamic>> rows) async {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet();
    if (defaultName != null && defaultName != 'Sheet1') {
      excel.delete(defaultName);
    }

    const sheetName = 'Sheet1';
    final sheet = excel[sheetName];

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    sheet.setRowHeight(0, 22);
    for (var col = 0; col < headers.length; col++) {
      _setCell(
        sheet,
        col: col,
        row: 0,
        value: TextCellValue(headers[col]),
        style: headerStyle,
      );
      sheet.setColumnWidth(col, 18);
    }

    for (var i = 0; i < rows.length; i++) {
      final row = i + 1;
      sheet.setRowHeight(row, 20);
      final data = rows[i];
      for (var col = 0; col < columns.length; col++) {
        final key = columns[col];
        final raw = data[key];
        final value = raw == null ? '' : raw.toString();
        _setCell(
          sheet,
          col: col,
          row: row,
          value: TextCellValue(value),
          style: dataStyle,
        );
      }
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('ساخت فایل اکسل ناموفق بود: $filePath');
    }

    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(Uint8List.fromList(encoded), flush: true);
  }

  static String? _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return null;
    if (value is TextCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value ? '1' : '0';
    if (value is DateCellValue) return value.asDateTimeLocal().toIso8601String();
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }
    return value.toString();
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
}
