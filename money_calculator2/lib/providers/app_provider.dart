import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class AppProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _goals = [];
  bool _termsAccepted = false;
  bool _isLoaded = false;
  String _currency = '₽';
  double _monthlyBudget = 50000;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Transaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get goals => _goals;
  bool get termsAccepted => _termsAccepted;
  bool get isLoaded => _isLoaded;
  String get currency => _currency;
  double get monthlyBudget => _monthlyBudget;

  AppProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // ─── Computed getters ───────────────────────────────────────────────

  List<Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalExpensesThisMonth => currentMonthTransactions
      .where((t) => t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);

  double get totalIncomeThisMonth => currentMonthTransactions
      .where((t) => !t.isExpense)
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncomeThisMonth - totalExpensesThisMonth;

  double get savingsRate =>
      totalIncomeThisMonth > 0 ? balance / totalIncomeThisMonth * 100 : 0;

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final t in currentMonthTransactions.where((t) => t.isExpense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  List<Transaction> getTransactionsByMonth(int year, int month) {
    return _transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, double> getExpensesByCategoryForMonth(int year, int month) {
    final map = <String, double>{};
    for (final t in getTransactionsByMonth(year, month).where((t) => t.isExpense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  double getBudgetUsed(String category) {
    return currentMonthTransactions
        .where((t) => t.isExpense && t.category == category)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getBudgetLimit(String category) {
    final now = DateTime.now();
    final budget = _budgets.firstWhere(
          (b) =>
      b.category == category &&
          b.month.year == now.year &&
          b.month.month == now.month,
      orElse: () => Budget(
        id: '',
        category: category,
        limit: 0,
        month: now,
      ),
    );
    return budget.limit;
  }

  List<Map<String, dynamic>> getLast7DaysExpenses() {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayTransactions = _transactions.where(
            (t) =>
        t.isExpense &&
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day,
      );
      result.add({
        'date': day,
        'amount': dayTransactions.fold(0.0, (s, t) => s + t.amount),
      });
    }
    return result;
  }

  // ─── CRUD ───────────────────────────────────────────────────────────

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _saveData();
    notifyListeners();
  }

  void updateTransaction(Transaction transaction) {
    final idx = _transactions.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) {
      _transactions[idx] = transaction;
      _saveData();
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _saveData();
    notifyListeners();
  }

  void addBudget(Budget budget) {
    final existing = _budgets.indexWhere(
          (b) =>
      b.category == budget.category &&
          b.month.year == budget.month.year &&
          b.month.month == budget.month.month,
    );
    if (existing != -1) {
      _budgets[existing] = budget;
    } else {
      _budgets.add(budget);
    }
    _saveData();
    notifyListeners();
  }

  void addGoal(SavingsGoal goal) {
    _goals.add(goal);
    _saveData();
    notifyListeners();
  }

  void updateGoalAmount(String id, double amount) {
    final idx = _goals.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _goals[idx].currentAmount += amount;
      _saveData();
      notifyListeners();
    }
  }

  void deleteGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    _saveData();
    notifyListeners();
  }

  String generateId() => _uuid.v4();

  void acceptTerms() {
    _termsAccepted = true;
    _saveData();
    notifyListeners();
  }

  void setMonthlyBudget(double amount) {
    _monthlyBudget = amount;
    _saveData();
    notifyListeners();
  }

  void setCurrency(String currency) {
    _currency = currency;
    _saveData();
    notifyListeners();
  }

  // ─── Persistence ────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _termsAccepted = prefs.getBool('terms_accepted') ?? false;
    _currency = prefs.getString('currency') ?? '₽';
    _monthlyBudget = prefs.getDouble('monthly_budget') ?? 50000;

    final txJson = prefs.getStringList('transactions') ?? [];
    _transactions =
        txJson.map((s) => Transaction.fromJson(jsonDecode(s))).toList();

    final budgetJson = prefs.getStringList('budgets') ?? [];
    _budgets = budgetJson.map((s) => Budget.fromJson(jsonDecode(s))).toList();

    final goalsJson = prefs.getStringList('goals') ?? [];
    _goals =
        goalsJson.map((s) => SavingsGoal.fromJson(jsonDecode(s))).toList();

    if (_transactions.isEmpty) {
      _seedDemoData();
    }

    _isLoaded = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', _termsAccepted);
    await prefs.setString('currency', _currency);
    await prefs.setDouble('monthly_budget', _monthlyBudget);
    await prefs.setStringList(
      'transactions',
      _transactions.map((t) => jsonEncode(t.toJson())).toList(),
    );
    await prefs.setStringList(
      'budgets',
      _budgets.map((b) => jsonEncode(b.toJson())).toList(),
    );
    await prefs.setStringList(
      'goals',
      _goals.map((g) => jsonEncode(g.toJson())).toList(),
    );
  }

  void _seedDemoData() {
    final now = DateTime.now();
    final categories = ['Еда', 'Транспорт', 'Развлечения', 'Здоровье', 'Связь'];
    final sampleExpenses = [
      ('Продукты гиппо', 3200.0, 'Еда'),
      ('Метро', 350.0, 'Транспорт'),
      ('Кино', 900.0, 'Развлечения'),
      ('Аптека', 780.0, 'Здоровье'),
      ('МТС', 600.0, 'Связь'),
      ('Кафе чиназес', 1450.0, 'Еда'),
      ('Яндекс.Такси', 480.0, 'Транспорт'),
      ('Spotify', 299.0, 'Развлечения'),
      ('Светофор', 2100.0, 'Еда'),
    ];

    for (int i = 0; i < sampleExpenses.length; i++) {
      final (title, amount, cat) = sampleExpenses[i];
      _transactions.add(Transaction(
        id: _uuid.v4(),
        title: title,
        amount: amount,
        category: cat,
        date: now.subtract(Duration(days: i * 2)),
        isExpense: true,
      ));
    }

    _transactions.add(Transaction(
      id: _uuid.v4(),
      title: 'Зарплата',
      amount: 75000,
      category: 'Прочее',
      date: now.subtract(const Duration(days: 5)),
      isExpense: false,
    ));

    for (final cat in categories) {
      _budgets.add(Budget(
        id: _uuid.v4(),
        category: cat,
        limit: cat == 'Еда' ? 15000 : cat == 'Транспорт' ? 3000 : 5000,
        month: DateTime(now.year, now.month),
      ));
    }
  }
}