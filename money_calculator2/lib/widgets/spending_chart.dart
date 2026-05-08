import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class SpendingBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String currency;

  const SpendingBarChart({
    super.key,
    required this.data,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.fold<double>(
      0,
      (max, item) => (item['amount'] as double) > max
          ? (item['amount'] as double)
          : max,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final amount = item['amount'] as double;
        final date = item['date'] as DateTime;
        final isToday = date.day == DateTime.now().day;
        final barHeight = maxAmount > 0 ? (amount / maxAmount) * 80 : 4;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: barHeight < 4 ? 4 : barHeight.toDouble(),
                  decoration: BoxDecoration(
                    gradient: isToday
                        ? AppTheme.primaryGradient
                        : LinearGradient(
                            colors: [
                              AppTheme.primary.withOpacity(0.3),
                              AppTheme.primary.withOpacity(0.5),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppFormatter.shortDate(date),
                  style: TextStyle(
                    color: isToday
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight:
                        isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}