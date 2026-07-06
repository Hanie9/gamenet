import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;

import '../core/utils/formatters.dart';
import '../core/utils/jalali_date.dart';
import '../models/cafe_order.dart';
import '../models/game_session.dart';
import 'database_service.dart';
import 'excel/excel_data_paths.dart';

class MonthlyReportSummary {
  const MonthlyReportSummary({
    required this.jalaliYear,
    required this.jalaliMonth,
    required this.totalRevenue,
    required this.totalPlayTime,
    required this.gamingRevenue,
    required this.cafeRevenue,
    required this.cafeItemSales,
  });

  final int jalaliYear;
  final int jalaliMonth;
  final int totalRevenue;
  final Duration totalPlayTime;
  final int gamingRevenue;
  final int cafeRevenue;
  final List<CafeItemSale> cafeItemSales;
}

class CafeItemSale {
  const CafeItemSale({
    required this.itemName,
    required this.quantity,
    required this.revenue,
  });

  final String itemName;
  final int quantity;
  final int revenue;
}

class MonthlyReportService {
  MonthlyReportService._();
  static final MonthlyReportService instance = MonthlyReportService._();

  final _db = DatabaseService.instance;

  Future<void> ensureReports() async {
    await _db.database;
    final sessions = await _db.getAllSessions();
    final orders = await _db.getAllCafeOrders();
    final earliest = _earliestJalaliMonth(sessions, orders);
    if (earliest == null) return;

    final lastCompleted = lastCompletedJalaliMonth();
    final dirs = await ExcelDataPaths.dataDirectories();

    for (final month in jalaliMonthsBetween(earliest, lastCompleted)) {
      final fileName = monthlyReportFileName(month.year, month.month);
      if (await _reportExists(dirs, fileName)) continue;

      final summary = _buildSummary(
        jalaliYear: month.year,
        jalaliMonth: month.month,
        sessions: sessions,
        orders: orders,
      );
      if (summary.totalRevenue == 0 && summary.totalPlayTime == Duration.zero) {
        continue;
      }

      await _writeReport(dirs, summary);
    }
  }

  Future<MonthlyReportSummary> generateReport(int jalaliYear, int jalaliMonth) async {
    await _db.database;
    final sessions = await _db.getAllSessions();
    final orders = await _db.getAllCafeOrders();
    final summary = _buildSummary(
      jalaliYear: jalaliYear,
      jalaliMonth: jalaliMonth,
      sessions: sessions,
      orders: orders,
    );
    final dirs = await ExcelDataPaths.dataDirectories();
    await _writeReport(dirs, summary);
    return summary;
  }

  Future<List<String>> listReportFiles() async {
    final dirs = await ExcelDataPaths.dataDirectories();
    if (dirs.isEmpty) return const [];

    final files = <String>{};
    for (final dir in dirs) {
      final directory = Directory(dir);
      if (!await directory.exists()) continue;
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (_isMonthlyReportFile(name)) files.add(name);
      }
    }

    final sorted = files.toList()
      ..sort((a, b) => _reportSortKey(b).compareTo(_reportSortKey(a)));
    return sorted;
  }

  ({int year, int month})? _earliestJalaliMonth(
    List<GameSession> sessions,
    List<CafeOrder> orders,
  ) {
    DateTime? earliest;

    void consider(DateTime value) {
      if (earliest == null || value.isBefore(earliest!)) {
        earliest = value;
      }
    }

    for (final session in sessions) {
      consider(session.createdAt);
      for (final segment in session.segments) {
        consider(segment.startTime);
        if (segment.endTime != null) consider(segment.endTime!);
      }
      for (final order in session.cafeOrders) {
        consider(order.createdAt);
      }
    }
    for (final order in orders) {
      consider(order.createdAt);
    }

    if (earliest == null) return null;
    final jalali = gregorianToJalaliDate(earliest!);
    return (year: jalali.year, month: jalali.month);
  }

  MonthlyReportSummary _buildSummary({
    required int jalaliYear,
    required int jalaliMonth,
    required List<GameSession> sessions,
    required List<CafeOrder> orders,
  }) {
    final rangeStart = jalaliMonthStart(jalaliYear, jalaliMonth);
    final rangeEnd = jalaliMonthEnd(jalaliYear, jalaliMonth);

    var totalPlayTime = Duration.zero;
    var gamingRevenue = 0;

    for (final session in sessions) {
      for (final segment in session.segments) {
        totalPlayTime += segment.durationForRange(
          rangeStart,
          rangeEnd,
          now: rangeEnd,
        );
        gamingRevenue += segment.costForRange(
          rangeStart,
          rangeEnd,
          now: rangeEnd,
        );
      }
    }

    final monthOrders = orders
        .where((order) => isInJalaliMonth(order.createdAt, jalaliYear, jalaliMonth))
        .toList();
    final cafeRevenue = monthOrders.fold(0, (sum, order) => sum + order.totalPrice);

    final salesByItem = <String, ({String name, int quantity, int revenue})>{};
    for (final order in monthOrders) {
      final current = salesByItem[order.itemId];
      salesByItem[order.itemId] = (
        name: order.itemName,
        quantity: (current?.quantity ?? 0) + order.quantity,
        revenue: (current?.revenue ?? 0) + order.totalPrice,
      );
    }

    final cafeItemSales = salesByItem.values
        .map(
          (sale) => CafeItemSale(
            itemName: sale.name,
            quantity: sale.quantity,
            revenue: sale.revenue,
          ),
        )
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    return MonthlyReportSummary(
      jalaliYear: jalaliYear,
      jalaliMonth: jalaliMonth,
      totalRevenue: gamingRevenue + cafeRevenue,
      totalPlayTime: totalPlayTime,
      gamingRevenue: gamingRevenue,
      cafeRevenue: cafeRevenue,
      cafeItemSales: cafeItemSales,
    );
  }

  Future<bool> _reportExists(List<String> dirs, String fileName) async {
    for (final dir in dirs) {
      if (await File(p.join(dir, fileName)).exists()) return true;
    }
    return false;
  }

  Future<void> _writeReport(
    List<String> dirs,
    MonthlyReportSummary summary,
  ) async {
    final bytes = _encode(summary);
    final fileName = monthlyReportFileName(summary.jalaliYear, summary.jalaliMonth);
    for (final dir in dirs) {
      final file = File(p.join(dir, fileName));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  }

  Uint8List _encode(MonthlyReportSummary summary) {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet();
    if (defaultName != null) {
      excel.delete(defaultName);
    }

    const sheetName = 'Sheet1';
    final sheet = excel[sheetName];
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final monthTitle =
        '${jalaliMonthName(summary.jalaliMonth)} ${summary.jalaliYear}';

    var row = 0;
    _setCell(
      sheet,
      col: 0,
      row: row,
      value: TextCellValue('گزارش ماهانه $monthTitle'),
      style: titleStyle,
    );
    _setCell(sheet, col: 1, row: row, value: TextCellValue(''), style: dataStyle);
    row++;

    final summaryRows = <(String, String)>[
      ('درآمد کل ماه', formatCurrency(summary.totalRevenue, suffix: '')),
      ('مجموع زمان بازی', formatDuration(summary.totalPlayTime)),
      ('درآمد بازی', formatCurrency(summary.gamingRevenue, suffix: '')),
      ('درآمد کافه', formatCurrency(summary.cafeRevenue, suffix: '')),
    ];

    for (final entry in summaryRows) {
      _setCell(
        sheet,
        col: 0,
        row: row,
        value: TextCellValue(entry.$1),
        style: headerStyle,
      );
      _setCell(
        sheet,
        col: 1,
        row: row,
        value: TextCellValue(entry.$2),
        style: dataStyle,
      );
      row++;
    }

    row++;
    _setCell(
      sheet,
      col: 0,
      row: row,
      value: TextCellValue('آیتم کافه'),
      style: headerStyle,
    );
    _setCell(
      sheet,
      col: 1,
      row: row,
      value: TextCellValue('تعداد فروش'),
      style: headerStyle,
    );
    _setCell(
      sheet,
      col: 2,
      row: row,
      value: TextCellValue('درآمد'),
      style: headerStyle,
    );
    row++;

    if (summary.cafeItemSales.isEmpty) {
      _setCell(
        sheet,
        col: 0,
        row: row,
        value: TextCellValue('—'),
        style: dataStyle,
      );
      _setCell(
        sheet,
        col: 1,
        row: row,
        value: TextCellValue('0'),
        style: dataStyle,
      );
      _setCell(
        sheet,
        col: 2,
        row: row,
        value: TextCellValue('0'),
        style: dataStyle,
      );
    } else {
      for (final item in summary.cafeItemSales) {
        _setCell(
          sheet,
          col: 0,
          row: row,
          value: TextCellValue(item.itemName),
          style: dataStyle,
        );
        _setCell(
          sheet,
          col: 1,
          row: row,
          value: TextCellValue('${item.quantity}'),
          style: dataStyle,
        );
        _setCell(
          sheet,
          col: 2,
          row: row,
          value: TextCellValue(formatCurrency(item.revenue, suffix: '')),
          style: dataStyle,
        );
        row++;
      }
    }

    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 18);

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('ساخت گزارش ماهانه ناموفق بود.');
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

  static bool _isMonthlyReportFile(String fileName) {
    if (!fileName.endsWith('.xlsx')) return false;
    const dataFiles = {
      ExcelDataPaths.customersFile,
      ExcelDataPaths.cafeItemsFile,
      ExcelDataPaths.sessionsFile,
      ExcelDataPaths.segmentsFile,
      ExcelDataPaths.cafeOrdersFile,
      ExcelDataPaths.billsFile,
      ExcelDataPaths.settingsFile,
    };
    if (dataFiles.contains(fileName)) return false;
    return RegExp(r'^[\u0600-\u06FF]+-\d{4}\.xlsx$').hasMatch(fileName);
  }

  static String _reportSortKey(String fileName) {
    final match = RegExp(r'^(.+)-(\d{4})\.xlsx$').firstMatch(fileName);
    if (match == null) return fileName;
    final month = jalaliMonthNames.indexOf(match.group(1)!);
    final year = int.tryParse(match.group(2)!) ?? 0;
    return '${year.toString().padLeft(4, '0')}${month.toString().padLeft(2, '0')}';
  }
}
