import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

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
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Цели',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Накопления и сбережения',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _AddGoalButton(provider: provider),
                ],
              ),
            ),
          ),
          if (provider.goals.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    const Text(
                      'Нет целей',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Создайте первую цель накопления,\nнапример "Отпуск" или "Новый ноутбук"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddGoalSheet(context, provider),
                      icon: const Icon(Icons.add),
                      label: const Text('Создать цель'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final goal = provider.goals[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _GoalCard(
                        goal: goal,
                        currency: currency,
                        onAddAmount: () =>
                            _showAddAmountSheet(context, provider, goal),
                        onDelete: () => provider.deleteGoal(goal.id),
                      ),
                    );
                  },
                  childCount: provider.goals.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static void _showAddGoalSheet(BuildContext context, AppProvider provider) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime targetDate =
        DateTime.now().add(const Duration(days: 180));
    Color selectedColor = AppTheme.primary;
    IconData selectedIcon = Icons.star_rounded;

    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      AppTheme.accentRed,
      const Color(0xFFA29BFE),
      const Color(0xFF6BCB77),
      const Color(0xFF74B9FF),
    ];

    final icons = [
      Icons.beach_access_rounded,
      Icons.laptop_rounded,
      Icons.directions_car_rounded,
      Icons.home_rounded,
      Icons.school_rounded,
      Icons.favorite_rounded,
      Icons.shopping_bag_rounded,
      Icons.star_rounded,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
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
                const Text(
                  'Новая цель',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                // Icon picker
                const Text(
                  'Иконка',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: icons.map((icon) {
                    final isSel = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setModal(() => selectedIcon = icon),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSel
                              ? selectedColor.withOpacity(0.2)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? selectedColor : Colors.transparent,
                          ),
                        ),
                        child: Icon(icon,
                            color: isSel ? selectedColor : AppTheme.textSecondary,
                            size: 22),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Color picker
                const Text(
                  'Цвет',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: colors.map((color) {
                    final isSel = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setModal(() => selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isSel
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Название цели',
                    hintText: 'Например: Отпуск в Турции',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Целевая сумма',
                    suffixText: provider.currency,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.primary,
                            surface: AppTheme.surface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModal(() => targetDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppTheme.textSecondary, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          'Срок: ${AppFormatter.date(targetDate)}',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount =
                          double.tryParse(amountCtrl.text) ?? 0;
                      if (titleCtrl.text.isNotEmpty && amount > 0) {
                        provider.addGoal(SavingsGoal(
                          id: const Uuid().v4(),
                          title: titleCtrl.text,
                          targetAmount: amount,
                          currentAmount: 0,
                          targetDate: targetDate,
                          color: selectedColor,
                          icon: selectedIcon,
                        ));
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text('Создать цель'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showAddAmountSheet(
    BuildContext context,
    AppProvider provider,
    SavingsGoal goal,
  ) {
    final ctrl = TextEditingController();
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
            Text(
              'Пополнить «${goal.title}»',
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
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text);
                  if (v != null && v > 0) {
                    provider.updateGoalAmount(goal.id, v);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Пополнить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGoalButton extends StatelessWidget {
  final AppProvider provider;
  const _AddGoalButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => GoalsScreen._showAddGoalSheet(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Новая',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final String currency;
  final VoidCallback onAddAmount;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.currency,
    required this.onAddAmount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft =
        goal.targetDate.difference(DateTime.now()).inDays;
    final isCompleted = goal.progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? goal.color.withOpacity(0.5)
              : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: goal.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(goal.icon, color: goal.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isCompleted
                          ? '🎉 Цель достигнута!'
                          : daysLeft > 0
                              ? 'Осталось $daysLeft дн.'
                              : 'Срок истёк',
                      style: TextStyle(
                        color: isCompleted
                            ? goal.color
                            : daysLeft <= 0
                                ? AppTheme.accentRed
                                : AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppTheme.surfaceElevated,
                icon: const Icon(Icons.more_vert,
                    color: AppTheme.textSecondary, size: 20),
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: AppTheme.accentRed, size: 18),
                        SizedBox(width: 8),
                        Text('Удалить',
                            style:
                                TextStyle(color: AppTheme.accentRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: goal.progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: goal.color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: goal.color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                AppFormatter.currency(goal.currentAmount, currency),
                style: TextStyle(
                  color: goal.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' / ${AppFormatter.currency(goal.targetAmount, currency)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${(goal.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: goal.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAddAmount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: goal.color,
                  side: BorderSide(color: goal.color.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '+ Пополнить',
                  style: TextStyle(
                    color: goal.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}