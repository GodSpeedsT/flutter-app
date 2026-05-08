import 'package:intl/intl.dart';

class AppFormatter {
  static String currency(double amount, String symbol) {
    final formatter = NumberFormat('#,##0.##', 'ru_RU');
    return '${formatter.format(amount)} $symbol';
  }

  static String shortCurrency(double amount, String symbol) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}М $symbol';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}К $symbol';
    }
    return '${amount.toStringAsFixed(0)} $symbol';
  }

  static String date(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ru').format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat('d MMM', 'ru').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'ru').format(date);
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Сегодня';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return DateFormat('d MMM', 'ru').format(date);
  }

  static String percent(double value) {
    return '${value.toStringAsFixed(1)}%';
  }
}

final List<String> kCategories = [
  'Еда',
  'Транспорт',
  'Развлечения',
  'Одежда',
  'Здоровье',
  'Жильё',
  'Образование',
  'Связь',
  'Прочее',
];

final Map<String, String> kCategoryIcons = {
  'Еда': '🍔',
  'Транспорт': '🚇',
  'Развлечения': '🎮',
  'Одежда': '👗',
  'Здоровье': '💊',
  'Жильё': '🏠',
  'Образование': '📚',
  'Связь': '📱',
  'Прочее': '💰',
};