import 'package:intl/intl.dart';

/// Centralized Indian currency formatting utilities.
/// Ensures consistent ₹ formatting across the application.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _fullFormatter =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static final NumberFormat _noDecimalFormatter =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  /// Format amount with full precision: ₹12,50,000.00
  static String format(double amount) => _fullFormatter.format(amount);

  /// Format amount without decimals: ₹12,50,000
  static String formatCompact(double amount) => _noDecimalFormatter.format(amount);

  /// Format amount in shortened Indian notation: ₹1.25 Cr, ₹50.00 L, ₹25K
  static String formatShort(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}
