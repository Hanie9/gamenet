import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';

/// خواندن و نوشتن یک جدول در فایل اکسل (ردیف اول = عنوان ستون‌ها)
/// روی ویندوز می‌تواند همزمان در چند مسیر (مثلاً C و D) ذخیره کند.
class ExcelFileStore {
  ExcelFileStore({
    required List<String> filePaths,
    required this.columns,
    required this.headers,
  }) : filePaths = List.unmodifiable(filePaths),
       assert(columns.length == headers.length),
       assert(filePaths.isNotEmpty);

  final List<String> filePaths;
  final List<String> columns;
  final List<String> headers;

  String get primaryPath => filePaths.first;

  Future<void> ensureExists() async {
    final existing = await _findExistingPath();
    if (existing != null) {
      await _mirrorFile(existing);
      return;
    }
    await writeAll(const []);
  }

  Future<String?> _findExistingPath() async {
    for (final path in filePaths) {
      if (await File(path).exists()) return path;
    }
    return null;
  }

  Future<void> _mirrorFile(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    if (bytes.isEmpty) return;
    for (final path in filePaths) {
      if (path == sourcePath) continue;
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  }

  Future<List<Map<String, dynamic>>> readAll() async {
    for (final path in filePaths) {
      final rows = await _readFromPath(path);
      if (rows.isNotEmpty || await File(path).exists()) {
        return rows;
      }
    }
    await ensureExists();
    return [];
  }

  Future<List<Map<String, dynamic>>> _readFromPath(String path) async {
    final file = File(path);
    if (!await file.exists()) return [];

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return [];

    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final sheet = excel.tables.values.first;
    if (sheet.maxRows <= 1) return [];

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
    final bytes = _encode(rows);
    for (final path in filePaths) {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  }

  Uint8List _encode(List<Map<String, dynamic>> rows) {
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
      throw StateError('ساخت فایل اکسل ناموفق بود: $primaryPath');
    }
    return Uint8List.fromList(encoded);
  }

  static String? _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return null;
    if (value is TextCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value ? '1' : '0';
    if (value is DateCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }
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
