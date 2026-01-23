import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class Helpers {
  // Format currency in FCFA
  static String formatCurrency(num amount) {
    final formatter = NumberFormat('#,###', Intl.getCurrentLocale());
    return '${formatter.format(amount)} FCFA';
  }

  // Format number with separator
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,###', Intl.getCurrentLocale());
    return formatter.format(number);
  }

  static double? parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double? extractRequiredAmount(dynamic data) {
    if (data is Map) {
      final value =
          data['required_amount'] ??
          data['requiredAmount'] ??
          data['amount'] ??
          data['price'];
      return parseAmount(value);
    }
    return null;
  }

  static String insufficientBalanceMessage({double? requiredAmount}) {
    if (requiredAmount != null && requiredAmount > 0) {
      return 'Solde insuffisant. Faites un depot de ${formatCurrency(requiredAmount)}.';
    }
    return 'Solde insuffisant. Faites un depot sur votre wallet.';
  }

  // Get time ago string
  static String getTimeAgo(DateTime dateTime) {
    final locale = Intl.getCurrentLocale().startsWith('fr') ? 'fr' : 'en';
    return timeago.format(dateTime, locale: locale);
  }

  // Format date
  static String formatDate(DateTime dateTime, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern, Intl.getCurrentLocale()).format(dateTime);
  }

  // Format date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(
      'dd/MM/yyyy HH:mm',
      Intl.getCurrentLocale(),
    ).format(dateTime);
  }

  // Format time
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm', Intl.getCurrentLocale()).format(dateTime);
  }

  // Get initials from name
  static String getInitials(String? firstName, String? lastName) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) {
      initials += firstName[0].toUpperCase();
    }
    if (lastName != null && lastName.isNotEmpty) {
      initials += lastName[0].toUpperCase();
    }
    return initials.isEmpty ? '?' : initials;
  }

  // Get avatar color from string
  static Color getAvatarColor(String text) {
    final colors = [
      const Color(0xFF6C5CE7),
      const Color(0xFFFF6B9D),
      const Color(0xFF00D9FF),
      const Color(0xFF00B894),
      const Color(0xFFFDAA0A),
      const Color(0xFFE74C3C),
      const Color(0xFF9B59B6),
      const Color(0xFF3498DB),
    ];
    final index = text.hashCode % colors.length;
    return colors[index.abs()];
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone (Cameroon format)
  static bool isValidPhone(String phone) {
    return RegExp(
      r'^(6[5-9][0-9]{7}|2[0-9]{8})$',
    ).hasMatch(phone.replaceAll(RegExp(r'[\s\-\+]'), ''));
  }

  // Validate username
  static bool isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Parse API error message
  static String parseErrorMessage(dynamic error) {
    if (error is Map && error.containsKey('message')) {
      return error['message'].toString();
    }
    if (error is String) {
      return error;
    }
    return 'Une erreur est survenue';
  }

  // Get flame emoji based on level
  static String getFlameEmoji(String? flameLevel) {
    switch (flameLevel) {
      case 'yellow':
        return '🔥';
      case 'orange':
        return '🔥🔥';
      case 'purple':
        return '💜🔥';
      default:
        return '';
    }
  }

  // Get flame color based on level
  static Color getFlameColor(String? flameLevel) {
    switch (flameLevel) {
      case 'yellow':
        return const Color(0xFFFFD700);
      case 'orange':
        return const Color(0xFFFF8C00);
      case 'purple':
        return const Color(0xFF9B59B6);
      default:
        return Colors.transparent;
    }
  }

  // Get gift tier color
  static Color getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      default:
        return Colors.grey;
    }
  }
}
