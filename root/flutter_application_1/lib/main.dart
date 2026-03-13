import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru', null);

  runApp(
    // Оборачиваем приложение в Provider для управления состоянием
    ChangeNotifierProvider(
      create: (context) => TransactionProvider(),
      child: const WhereIsTheMoneyApp(),
    ),
  );
}

class WhereIsTheMoneyApp extends StatelessWidget {
  const WhereIsTheMoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Где деньги?',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Рекомендую добавить шрифты позже
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Автоматический выбор темы
      home: const MainNavigationScreen(),
    );
  }
}

// ==================== МОДЕЛИ ДАННЫХ ====================

enum TransactionType { income, expense }

class TransactionCategory {
  final String name;
  final IconData icon;
  final Color color;

  const TransactionCategory(this.name, this.icon, this.color);
}

// Предустановленные категории
class Categories {
  static const food = TransactionCategory(
    'Продукты',
    Icons.shopping_cart,
    Colors.orange,
  );
  static const transport = TransactionCategory(
    'Транспорт',
    Icons.directions_car,
    Colors.blue,
  );
  static const entertainment = TransactionCategory(
    'Развлечения',
    Icons.movie,
    Colors.purple,
  );
  static const salary = TransactionCategory(
    'Зарплата',
    Icons.attach_money,
    Colors.green,
  );
  static const other = TransactionCategory(
    'Другое',
    Icons.category,
    Colors.grey,
  );
}

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final TransactionCategory category;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });
}

// ==================== STATE MANAGEMENT (PROVIDER) ====================

class TransactionProvider with ChangeNotifier {
  // Фейковые данные для демонстрации UI
  List<Transaction> _transactions = [
    Transaction(
      id: '1',
      title: 'Пятерочка',
      amount: 1200,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.expense,
      category: Categories.food,
    ),
    Transaction(
      id: '2',
      title: 'Метро',
      amount: 150,
      date: DateTime.now(),
      type: TransactionType.expense,
      category: Categories.transport,
    ),
    Transaction(
      id: '3',
      title: 'Кино',
      amount: 800,
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.expense,
      category: Categories.entertainment,
    ),
    Transaction(
      id: '4',
      title: 'Аванс',
      amount: 45000,
      date: DateTime.now().subtract(const Duration(days: 5)),
      type: TransactionType.income,
      category: Categories.salary,
    ),
    Transaction(
      id: '5',
      title: 'Ресторан',
      amount: 3500,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.expense,
      category: Categories.food,
    ),
  ];

  String _searchQuery = '';

  List<Transaction> get transactions {
    if (_searchQuery.isEmpty) {
      return [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    }
    return _transactions
        .where(
          (tx) => tx.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalBalance {
    return _transactions.fold(0.0, (sum, item) {
      return item.type == TransactionType.income
          ? sum + item.amount
          : sum - item.amount;
    });
  }

  double get totalExpenses {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Аналитика: самая затратная категория
  TransactionCategory? get topExpenseCategory {
    if (_transactions.where((t) => t.type == TransactionType.expense).isEmpty)
      return null;

    Map<TransactionCategory, double> categorySums = {};
    for (var tx in _transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
    }

    var topCategory = categorySums.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return topCategory;
  }

  // Простая генерация советов
  String get financialAdvice {
    final topCat = topExpenseCategory;
    if (topCat == null) return "Записывайте расходы, чтобы получать советы.";
    if (topCat.name == 'Продукты')
      return "Совет: Попробуйте планировать меню на неделю, чтобы снизить траты на спонтанные покупки еды.";
    if (topCat.name == 'Развлечения')
      return "Совет: Вы тратите много на развлечения. Проверьте бесплатные мероприятия в городе.";
    return "Совет: Откладывайте 10% от доходов в день зарплаты.";
  }

  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    notifyListeners(); // Обновляет UI при добавлении
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}

// ==================== UI СЛОЙ ====================

// Базовая навигация (Bottom Navigation Bar)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Сводка',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'История',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Здесь будет вызов экрана добавления транзакции
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Экран добавления будет реализован следующим шагом',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Операция'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Экран 1: Сводка (Дашборд с аналитикой и советами)
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Сводка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Карточка баланса
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Текущий баланс',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${provider.totalBalance.toStringAsFixed(0)} ₽',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Блок рекомендаций
          const Text(
            'Аналитика и советы',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 40,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      provider.financialAdvice,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Самая затратная категория
          if (provider.topExpenseCategory != null) ...[
            const Text(
              'Основная статья расходов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: CircleAvatar(
                backgroundColor: provider.topExpenseCategory!.color.withOpacity(
                  0.2,
                ),
                child: Icon(
                  provider.topExpenseCategory!.icon,
                  color: provider.topExpenseCategory!.color,
                ),
              ),
              title: Text(provider.topExpenseCategory!.name),
              subtitle: const Text('Вы тратите здесь больше всего'),
              trailing: const Icon(Icons.trending_down, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

// Экран 2: История с поиском и фильтрацией
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final transactions = provider.transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('История операций')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по названию...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
              ),
              onChanged: (value) => provider.setSearchQuery(value),
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('Транзакций не найдено'))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isIncome = tx.type == TransactionType.income;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.category.color.withOpacity(0.2),
                          child: Icon(
                            tx.category.icon,
                            color: tx.category.color,
                          ),
                        ),
                        title: Text(
                          tx.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy', 'ru').format(tx.date),
                        ),
                        trailing: Text(
                          '${isIncome ? '+' : '-'} ${tx.amount.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
