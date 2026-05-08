import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;
  int _selectedMonthOffset = 0; // 0 = current, -1 = prev, etc.
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  DateTime get _displayMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _selectedMonthOffset);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currency = provider.currency;
    final month = _displayMonth;
    final byCategory =
        provider.getExpensesByCategoryForMonth(month.year, month.month);
    final transactions =
        provider.getTransactionsByMonth(month.year, month.month);
    final totalExpenses = transactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);
    final totalIncome = transactions
        .where((t) => !t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Аналитика',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Month selector
                  _MonthSelector(
                    month: month,
                    onPrev: () =>
                        setState(() => _selectedMonthOffset--),
                    onNext: _selectedMonthOffset < 0
                        ? () => setState(() => _selectedMonthOffset++)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  // Summary row
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'Расходы',
                          amount: totalExpenses,
                          currency: currency,
                          color: AppTheme.accentRed,
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Доходы',
                          amount: totalIncome,
                          currency: currency,
                          color: AppTheme.primary,
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'По категориям'),
                        Tab(text: 'Тренды'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ─── Categories tab ────────────────────────────────────
            _CategoriesTab(
              byCategory: byCategory,
              totalExpenses: totalExpenses,
              currency: currency,
              touchedIndex: _touchedIndex,
              onTouch: (i) => setState(() => _touchedIndex = i),
            ),
            // ─── Trends tab ────────────────────────────────────────
            _TrendsTab(provider: provider, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  const _MonthSelector({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
          onPressed: onPrev,
        ),
        Text(
          AppFormatter.monthYear(month),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: onNext != null
                ? AppTheme.textPrimary
                : AppTheme.textSecondary,
          ),
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatter.shortCurrency(amount, currency),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final Map<String, double> byCategory;
  final double totalExpenses;
  final String currency;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _CategoriesTab({
    required this.byCategory,
    required this.totalExpenses,
    required this.currency,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return const Center(
        child: Text(
          'Нет данных за этот месяц',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = sorted.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final color = AppTheme.getCategoryColor(e.key);
      final isTouched = i == touchedIndex;
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: isTouched ? '${(e.value / totalExpenses * 100).toStringAsFixed(1)}%' : '',
        radius: isTouched ? 70 : 56,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        badgeWidget: !isTouched
            ? null
            : Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      onTouch(-1);
                      return;
                    }
                    onTouch(response.touchedSection!.touchedSectionIndex);
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...sorted.map((e) {
            final color = AppTheme.getCategoryColor(e.key);
            final pct = totalExpenses > 0 ? e.value / totalExpenses : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    kCategoryIcons[e.key] ?? '💰',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatter.currency(e.value, currency),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        AppFormatter.percent(pct * 100),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrendsTab extends StatelessWidget {
  final AppProvider provider;
  final String currency;

  const _TrendsTab({required this.provider, required this.currency});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i));
      final expenses = provider
          .getTransactionsByMonth(m.year, m.month)
          .where((t) => t.isExpense)
          .fold(0.0, (s, t) => s + t.amount);
      final income = provider
          .getTransactionsByMonth(m.year, m.month)
          .where((t) => !t.isExpense)
          .fold(0.0, (s, t) => s + t.amount);
      return {'month': m, 'expenses': expenses, 'income': income};
    });

    final maxVal = months.fold<double>(
      0,
      (max, m) {
        final v = (m['expenses'] as double) > (m['income'] as double)
            ? m['expenses'] as double
            : m['income'] as double;
        return v > max ? v : max;
      },
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Динамика за 6 месяцев',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Legend(color: AppTheme.accentRed, label: 'Расходы'),
                    const SizedBox(width: 16),
                    _Legend(color: AppTheme.primary, label: 'Доходы'),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: maxVal == 0
                      ? const Center(
                          child: Text(
                            'Нет данных',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxVal / 4,
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: AppTheme.divider,
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= months.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final m = months[i]['month'] as DateTime;
                                    return Text(
                                      AppFormatter.shortDate(
                                          DateTime(m.year, m.month)),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              _buildLine(
                                months
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                          e.key.toDouble(),
                                          e.value['expenses'] as double,
                                        ))
                                    .toList(),
                                AppTheme.accentRed,
                              ),
                              _buildLine(
                                months
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(
                                          e.key.toDouble(),
                                          e.value['income'] as double,
                                        ))
                                    .toList(),
                                AppTheme.primary,
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Insights
          _InsightsCard(provider: provider, currency: currency),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
          radius: 4,
          color: color,
          strokeWidth: 2,
          strokeColor: AppTheme.background,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.08),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 24,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      );
}

class _InsightsCard extends StatelessWidget {
  final AppProvider provider;
  final String currency;

  const _InsightsCard({required this.provider, required this.currency});

  @override
  Widget build(BuildContext context) {
    final savingsRate = provider.savingsRate;
    final topCategory = provider.expensesByCategory.entries.isEmpty
        ? null
        : (provider.expensesByCategory.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Инсайты',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsightRow(
            icon: '📊',
            text: savingsRate >= 20
                ? 'Отлично! Вы откладываете ${savingsRate.toStringAsFixed(0)}% дохода'
                : savingsRate >= 0
                    ? 'Норма сбережений ${savingsRate.toStringAsFixed(0)}%. Рекомендуется 20%+'
                    : 'Расходы превышают доходы в этом месяце',
            color: savingsRate >= 20
                ? AppTheme.primary
                : savingsRate >= 0
                    ? AppTheme.accent
                    : AppTheme.accentRed,
          ),
          if (topCategory != null) ...[
            const SizedBox(height: 12),
            _InsightRow(
              icon: kCategoryIcons[topCategory.key] ?? '💰',
              text:
                  'Больше всего тратите на «${topCategory.key}» — ${AppFormatter.currency(topCategory.value, currency)}',
              color: AppTheme.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _InsightRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      );
}