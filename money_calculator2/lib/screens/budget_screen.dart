import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currency = provider.currency;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Бюджеты',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatter.monthYear(DateTime.now()),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Overall budget
                  _OverallCard(provider: provider, currency: currency),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text(
                        'По категориям',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _AddBudgetButton(provider: provider),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = kCategories[index];
                  final limit = provider.getBudgetLimit(cat);
                  final used = provider.getBudgetUsed(cat);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BudgetCard(
                      category: cat,
                      limit: limit,
                      used: used,
                      currency: currency,
                      onSetBudget: () =>
                          _showBudgetDialog(context, provider, cat, limit),
                    ),
                  );
                },
                childCount: kCategories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog(
    BuildContext context,
    AppProvider provider,
    String category,
    double currentLimit,
  ) {
    final ctrl = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Бюджет: $category',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: provider.currency,
                suffixStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text);
                  if (v != null && v > 0) {
                    final now = DateTime.now();
                    provider.addBudget(Budget(
                      id: const Uuid().v4(),
                      category: category,
                      limit: v,
                      month: DateTime(now.year, now.month),
                    ));
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Установить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final AppProvider provider;
  final String currency;
  const _OverallCard({required this.provider, required this.currency});

  @override
  Widget build(BuildContext context) {
    final budget = provider.monthlyBudget;
    final spent = provider.totalExpensesThisMonth;
    final pct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - spent;
    final isOverBudget = spent > budget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isOverBudget
            ? LinearGradient(
                colors: [
                  AppTheme.accentRed.withOpacity(0.2),
                  AppTheme.accentRed.withOpacity(0.05),
                ],
              )
            : LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.15),
                  AppTheme.primary.withOpacity(0.03),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverBudget
              ? AppTheme.accentRed.withOpacity(0.4)
              : AppTheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Общий бюджет',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showSetBudgetDialog(context, provider),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Изменить',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatter.currency(spent, currency),
                style: TextStyle(
                  color: isOverBudget ? AppTheme.accentRed : AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  ' / ${AppFormatter.currency(budget, currency)}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(
                isOverBudget ? AppTheme.accentRed : AppTheme.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOverBudget
                ? 'Превышение: ${AppFormatter.currency(spent - budget, currency)}'
                : 'Осталось: ${AppFormatter.currency(remaining, currency)}',
            style: TextStyle(
              color: isOverBudget ? AppTheme.accentRed : AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(
        text: provider.monthlyBudget.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Установить общий бюджет',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: provider.currency,
                suffixStyle: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text);
                  if (v != null && v > 0) provider.setMonthlyBudget(v);
                  Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String category;
  final double limit;
  final double used;
  final String currency;
  final VoidCallback onSetBudget;

  const _BudgetCard({
    required this.category,
    required this.limit,
    required this.used,
    required this.currency,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final hasLimit = limit > 0;
    final pct = hasLimit ? (used / limit).clamp(0.0, 1.0) : 0.0;
    final isOver = used > limit && hasLimit;
    final color = AppTheme.getCategoryColor(category);
    final barColor = isOver ? AppTheme.accentRed : color;

    return GestureDetector(
      onTap: onSetBudget,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOver
                ? AppTheme.accentRed.withOpacity(0.4)
                : AppTheme.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      kCategoryIcons[category] ?? '💰',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!hasLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Задать',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppFormatter.currency(used, currency)} / ${AppFormatter.currency(limit, currency)}',
                        style: TextStyle(
                          color:
                              isOver ? AppTheme.accentRed : AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isOver
                            ? 'Перерасход!'
                            : '${AppFormatter.percent(pct * 100)} использовано',
                        style: TextStyle(
                          color: isOver
                              ? AppTheme.accentRed
                              : AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (hasLimit) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppTheme.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddBudgetButton extends StatelessWidget {
  final AppProvider provider;
  const _AddBudgetButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCategoryPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppTheme.primary, size: 16),
            SizedBox(width: 4),
            Text(
              'Добавить',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите категорию',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCategories.map((cat) {
                final color = AppTheme.getCategoryColor(cat);
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(kCategoryIcons[cat] ?? '💰',
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(cat,
                            style: TextStyle(color: color, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}