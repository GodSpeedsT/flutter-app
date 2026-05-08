import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'terms_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

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
                    'Профиль',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats summary
                  _StatsCard(provider: provider),
                  const SizedBox(height: 20),

                  // Settings
                  _SectionHeader('Настройки'),
                  const SizedBox(height: 12),
                  _SettingsGroup(children: [
                    _CurrencyTile(provider: provider),
                    _BudgetTile(provider: provider),
                  ]),
                  const SizedBox(height: 20),

                  // Theme
                  _SectionHeader('Внешний вид'),
                  const SizedBox(height: 12),
                  _SettingsGroup(children: [
                    _ThemeTile(),
                  ]),
                  const SizedBox(height: 20),

                  // Legal
                  _SectionHeader('Информация'),
                  const SizedBox(height: 12),
                  _SettingsGroup(children: [
                    _NavTile(
                      icon: Icons.description_outlined,
                      label: 'Условия использования',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Tips
                  _TipsCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map((e) => Column(children: [
          e.value,
          if (e.key < children.length - 1)
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppTheme.divider,
            ),
        ]))
            .toList(),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final AppProvider provider;
  const _StatsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              label: 'Операций',
              value: '${provider.transactions.length}',
            ),
          ),
          Expanded(
            child: _StatItem(
              label: 'Расходы (мес.)',
              value: AppFormatter.shortCurrency(
                  provider.totalExpensesThisMonth, provider.currency),
            ),
          ),
          Expanded(
            child: _StatItem(
              label: 'Накопления',
              value: '${provider.savingsRate.toStringAsFixed(0)}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class _CurrencyTile extends StatelessWidget {
  final AppProvider provider;
  const _CurrencyTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.currency_ruble, color: AppTheme.textSecondary),
      title: const Text('Валюта', style: TextStyle(color: AppTheme.textPrimary)),
      trailing: DropdownButton<String>(
        value: provider.currency,
        dropdownColor: AppTheme.surfaceElevated,
        style: const TextStyle(color: AppTheme.textPrimary),
        underline: const SizedBox(),
        items: const [
          DropdownMenuItem(value: '₽', child: Text('₽ Рубль')),
          DropdownMenuItem(value: '\$', child: Text('\$ Доллар')),
          DropdownMenuItem(value: '€', child: Text('€ Евро')),
          DropdownMenuItem(value: '¥', child: Text('¥ Юань')),
        ],
        onChanged: (v) {
          if (v != null) provider.setCurrency(v);
        },
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  final AppProvider provider;
  const _BudgetTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined,
          color: AppTheme.textSecondary),
      title:
      const Text('Месячный бюджет', style: TextStyle(color: AppTheme.textPrimary)),
      trailing: Text(
        AppFormatter.shortCurrency(provider.monthlyBudget, provider.currency),
        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
      ),
      onTap: () => _showBudgetDialog(context, provider),
    );
  }

  void _showBudgetDialog(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(
        text: provider.monthlyBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Месячный бюджет',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Сумма'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) provider.setMonthlyBudget(v);
              Navigator.pop(context);
            },
            child:
            const Text('Сохранить', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: Icon(Icons.brightness_6_outlined, color: AppTheme.textSecondary),
      title: Text('Тема', style: TextStyle(color: AppTheme.textPrimary)),
      trailing: Text('Тёмная', style: TextStyle(color: AppTheme.textSecondary)),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      trailing:
      const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Советы по экономии',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          _Tip('📊', 'Отслеживайте расходы',
              'Регулярно проверяйте куда уходят деньги'),
          SizedBox(height: 12),
          _Tip('🎯', 'Установите лимиты',
              'Контролируйте траты по категориям'),
          SizedBox(height: 12),
          _Tip('💰', 'Правило 50/30/20',
              '50% нужды, 30% желания, 20% накопления'),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  const _Tip(this.emoji, this.title, this.description);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(description,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    ],
  );
}