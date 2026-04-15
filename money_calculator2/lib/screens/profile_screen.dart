import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Настройки',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Тема'),
                    trailing: DropdownButton<ThemeMode>(
                      value: settings.themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Системная'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Светлая'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Темная'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) settings.setThemeMode(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Валюта'),
                    trailing: DropdownButton<String>(
                      value: settings.currency,
                      items: const [
                        DropdownMenuItem(value: '₽', child: Text('Рубль (₽)')),
                        DropdownMenuItem(value: '\$', child: Text('Доллар (\$)')),
                        DropdownMenuItem(value: '€', child: Text('Евро (€)')),
                      ],
                      onChanged: (value) {
                        if (value != null) settings.setCurrency(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Советы по экономии',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildTip('📊', 'Отслеживайте расходы', 'Регулярно проверяйте куда уходят деньги'),
                  _buildTip('🎯', 'Установите лимиты', 'Контролируйте траты по категориям'),
                  _buildTip('💰', 'Правило 50/30/20', '50% нужды, 30% желания, 20% накопления'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}