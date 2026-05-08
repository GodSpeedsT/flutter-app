import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/receipt_scanner_screen.dart';
import 'screens/terms_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  runApp(const MoneyCalculatorApp());
}

class MoneyCalculatorApp extends StatelessWidget {
  const MoneyCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Калькулятор расходов',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}

// Главный виджет, который решает, что показывать
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Если условия не приняты - показываем экран с условиями
        if (appProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
              ),
            ),
          );
        }
        if(!appProvider.termsAccepted) {
          return const TermsScreen();
        }
        // Если условия приняты - показываем основное приложение
        return const MainAppScreen();
      },
    );
  }
}

// Основной экран приложения с навигацией
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
    ReceiptScannerScreen(),
    BudgetScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withOpacity(0.15),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.home, color: AppTheme.primary),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.bar_chart, color: AppTheme.primary),
            label: 'Аналитика',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.receipt, color: AppTheme.primary),
            label: 'Чек',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.account_balance_wallet, color: AppTheme.primary),
            label: 'Бюджет',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.savings, color: AppTheme.primary),
            label: 'Цели',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'Профиль',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.background,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}