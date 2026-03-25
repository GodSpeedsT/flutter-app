import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  String _searchQuery = '';

  TransactionProvider() {
    _loadMockData();
  }

  void _loadMockData() {
    _transactions = [
      Transaction(
        id: const Uuid().v4(),
        title: 'Пятерочка',
        amount: 1250,
        date: DateTime.now(),
        type: TransactionType.expense,
        category: Categories.getCategoryById('food'),
        note: 'Продукты на неделю',
      ),
      Transaction(
        id: const Uuid().v4(),
        title: 'Яндекс.Такси',
        amount: 350,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        category: Categories.getCategoryById('transport'),
      ),
      Transaction(
        id: const Uuid().v4(),
        title: 'Квартплата',
        amount: 4500,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.expense,
        category: Categories.getCategoryById('bills'),
      ),
      Transaction(
        id: const Uuid().v4(),
        title: 'Зарплата',
        amount: 75000,
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: TransactionType.income,
        category: Categories.getCategoryById('salary'),
        note: 'Аванс',
      ),
    ];
  }

  List<Transaction> get transactions {
    var filtered = List<Transaction>.from(_transactions);
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) => 
        tx.title.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  double get totalBalance {
    return _transactions.fold(0.0, (sum, item) {
      return item.type == TransactionType.income
          ? sum + item.amount
          : sum - item.amount;
    });
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<TransactionCategory, double> getExpensesByCategory() {
    Map<TransactionCategory, double> result = {};
    for (var tx in _transactions.where((t) => t.type == TransactionType.expense)) {
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }
    return result;
  }

  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}