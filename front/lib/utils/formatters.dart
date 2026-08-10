import 'package:intl/intl.dart';

class Formatters {
  // Format currency in Tunisian Dinar (TND)
  // Tunisia uses: space as thousands separator, dot as decimal separator
  // Example: 20000.500 → "20 000.500 DT" or "20.000 DT" for whole dinars
  static String currency(double amount) {
    // Use a custom pattern: space for thousands, dot for decimals
    // The pattern #,##0.000 with proper locale substitution
    final formatter = NumberFormat('#,##0.000', 'en_US');
    String formatted = formatter.format(amount);
    
    // Replace comma with space for thousands separator (Tunisian format)
    formatted = formatted.replaceAll(',', ' ');
    
    return '$formatted DT';
  }
  
  // Format number with thousand separators (Tunisian format: space separator)
  static String number(double number) {
    final formatter = NumberFormat('#,##0.###', 'en_US');
    String formatted = formatter.format(number);
    // Replace comma with space for thousands separator
    return formatted.replaceAll(',', ' ');
  }
  
  // Format percentage
  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
  
  // Format date (dd/MM/yyyy)
  static String date(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
  
  // Format date with time (dd/MM/yyyy HH:mm)
  static String dateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  // Format time (HH:mm)
  static String time(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  // Format relative time (e.g., "2 hours ago", "yesterday")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
  
  // Format quantity with unit
  static String quantityWithUnit(double quantity, String unit) {
    return '${number(quantity)} $unit';
  }
}
