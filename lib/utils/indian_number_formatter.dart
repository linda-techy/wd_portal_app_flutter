import 'package:intl/intl.dart';

/// Indian-numbering-system formatters (lakhs/crores grouping: #,##,##0).
///
/// 6902624.76 → "69,02,624.76"  via [formatINRWithPaisa]
/// 6902624.76 → "₹69,02,625"    via [formatINR]
/// 2375.0     → "2,375"          via [formatWholeIndianNumber]
class IndianNumberFormatter {
  IndianNumberFormatter._();

  static final NumberFormat _withPaisa =
      NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9', decimalDigits: 2);

  static final NumberFormat _wholeRupee =
      NumberFormat.currency(locale: 'en_IN', symbol: '\u20b9', decimalDigits: 0);

  static final NumberFormat _wholeNumber =
      NumberFormat.decimalPattern('en_IN');

  /// "₹69,02,624.76" — full precision with paisa.
  static String formatINRWithPaisa(num? n) =>
      _withPaisa.format(n ?? 0);

  /// "₹69,02,625" — rounded to nearest rupee, with grouping.
  static String formatINR(num? n) => _wholeRupee.format(n ?? 0);

  /// "2,375" — non-monetary number with Indian grouping (sqft, counts, etc).
  static String formatWholeIndianNumber(num? n) => _wholeNumber.format(n ?? 0);
}
