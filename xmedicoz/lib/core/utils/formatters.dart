import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹ ',
    decimalDigits: 0,
  );

  /// Formats amount into Indian currency format: ₹ 1,45,200.00
  static String formatCurrency(double amount, {bool showDecimals = true}) {
    if (showDecimals) {
      return _currencyFormat.format(amount);
    }
    return _compactCurrency.format(amount);
  }

  /// Compact format for cards, e.g. ₹ 1.45 L or ₹ 25.8 K
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return '₹ ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹ ${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹ ${(amount / 1000).toStringAsFixed(1)} k';
    }
    return '₹ ${amount.toStringAsFixed(0)}';
  }

  /// Formats date into "07 Sep 2026, 03:45 PM"
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// Formats date into "07 Sep 2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Formats date into "03:45 PM"
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }
}
