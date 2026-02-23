import 'package:intl/intl.dart';

/// Extension methods for String class
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Convert to title case
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number (10 digits)
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^\d{10}$');
    return phoneRegex.hasMatch(this);
  }

  /// Remove extra whitespace
  String get trimAll {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// Extension methods for DateTime class
extension DateTimeExtensions on DateTime {
  /// Format as 'dd MMM yyyy' (e.g., '23 Feb 2026')
  String get formatted {
    return DateFormat('dd MMM yyyy').format(this);
  }

  /// Format as 'dd/MM/yyyy'
  String get shortFormatted {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// Format as 'dd MMM yyyy, hh:mm a' (e.g., '23 Feb 2026, 10:30 AM')
  String get formattedWithTime {
    return DateFormat('dd MMM yyyy, hh:mm a').format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Get relative time string (e.g., '2 hours ago', 'yesterday', '3 days ago')
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return 'yesterday';
      }
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Get date at start of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get date at end of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }
}

/// Extension methods for num (int, double)
extension NumExtensions on num {
  /// Format as currency (₹)
  String get toCurrency {
    return '₹${toStringAsFixed(2)}';
  }

  /// Format with commas (e.g., 1,000,000)
  String get withCommas {
    return NumberFormat('#,##,###').format(this);
  }
}

/// Extension methods for List
extension ListExtensions<T> on List<T> {
  /// Get element at index or null if out of range
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Split list into chunks of specified size
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}
