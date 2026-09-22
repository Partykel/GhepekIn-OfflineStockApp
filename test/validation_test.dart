import 'package:flutter_test/flutter_test.dart';

String? validateProductName(String? value) {
  if (value == null || value.trim().isEmpty) return 'Nama produk wajib diisi';
  return null;
}

String? validateSellPrice(String? value) {
  if (value == null || value.isEmpty) return 'Harga jual wajib diisi';
  final parsed = double.tryParse(value);
  if (parsed == null) return 'Format harga tidak valid';
  if (parsed <= 0) return 'Harga jual harus lebih dari 0';
  return null;
}

String? validateCostPrice(String? value, String? sellPriceStr) {
  if (value == null || value.isEmpty) return 'Harga modal wajib diisi';
  final parsed = double.tryParse(value);
  if (parsed == null) return 'Format harga tidak valid';
  if (parsed < 0) return 'Harga modal tidak boleh negatif';
  final sellPrice = double.tryParse(sellPriceStr ?? '');
  if (sellPrice != null && parsed > sellPrice) {
    return 'Harga modal tidak boleh melebihi harga jual';
  }
  return null;
}

String? validateMinStock(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null) return 'Harus berupa angka';
  if (parsed < 0) return 'Tidak boleh negatif';
  return null;
}

String? validateExpenseAmount(String? value) {
  if (value == null || value.isEmpty) return 'Nominal wajib diisi';
  final parsed = double.tryParse(value);
  if (parsed == null) return 'Format nominal tidak valid';
  if (parsed <= 0) return 'Nominal harus lebih dari 0';
  return null;
}

void main() {
  group('Validasi nama produk', () {
    test(
      'null menghasilkan error',
      () => expect(validateProductName(null), isNotNull),
    );
    test(
      'empty menghasilkan error',
      () => expect(validateProductName(''), isNotNull),
    );
    test(
      'spasi saja menghasilkan error',
      () => expect(validateProductName('   '), isNotNull),
    );
    test(
      'nama valid lolos',
      () => expect(validateProductName('Keripik'), isNull),
    );
  });

  group('Validasi harga jual', () {
    test(
      'empty menghasilkan error',
      () => expect(validateSellPrice(''), isNotNull),
    );
    test(
      'bukan angka menghasilkan error',
      () => expect(validateSellPrice('abc'), isNotNull),
    );
    test(
      'nol menghasilkan error',
      () => expect(validateSellPrice('0'), isNotNull),
    );
    test(
      'negatif menghasilkan error',
      () => expect(validateSellPrice('-1000'), isNotNull),
    );
    test(
      'nilai valid lolos',
      () => expect(validateSellPrice('15000'), isNull),
    );
  });

  group('Validasi harga modal', () {
    test(
      'negatif menghasilkan error',
      () => expect(validateCostPrice('-100', '10000'), isNotNull),
    );
    test(
      'modal di atas jual menghasilkan error',
      () => expect(validateCostPrice('20000', '15000'), isNotNull),
    );
    test(
      'modal sama dengan jual masih valid',
      () => expect(validateCostPrice('15000', '15000'), isNull),
    );
    test(
      'modal di bawah jual valid',
      () => expect(validateCostPrice('8000', '15000'), isNull),
    );
    test(
      'modal nol tetap valid',
      () => expect(validateCostPrice('0', '15000'), isNull),
    );
  });

  group('Validasi stok minimum', () {
    test(
      'kosong valid karena opsional',
      () => expect(validateMinStock(''), isNull),
    );
    test(
      'negatif menghasilkan error',
      () => expect(validateMinStock('-5'), isNotNull),
    );
    test(
      'bukan angka menghasilkan error',
      () => expect(validateMinStock('abc'), isNotNull),
    );
    test(
      'nol valid',
      () => expect(validateMinStock('0'), isNull),
    );
    test(
      'positif valid',
      () => expect(validateMinStock('10'), isNull),
    );
  });

  group('Validasi nominal pengeluaran', () {
    test(
      'empty menghasilkan error',
      () => expect(validateExpenseAmount(''), isNotNull),
    );
    test(
      'nol menghasilkan error',
      () => expect(validateExpenseAmount('0'), isNotNull),
    );
    test(
      'negatif menghasilkan error',
      () => expect(validateExpenseAmount('-5000'), isNotNull),
    );
    test(
      'bukan angka menghasilkan error',
      () => expect(validateExpenseAmount('abc'), isNotNull),
    );
    test(
      'nilai valid lolos',
      () => expect(validateExpenseAmount('50000'), isNull),
    );
  });
}
