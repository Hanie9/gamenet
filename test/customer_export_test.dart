import 'package:flutter_test/flutter_test.dart';
import 'package:gamenet/models/customer.dart';
import 'package:gamenet/services/customer_export_service.dart';

void main() {
  test('buildExcelBytes creates non-empty xlsx', () {
    final customers = [
      Customer(
        id: '1',
        firstName: 'علی',
        lastName: 'احمدی',
        phone: '09120000000',
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    final bytes = CustomerExportService.buildExcelBytes(customers);
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });
}
