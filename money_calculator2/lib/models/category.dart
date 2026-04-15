import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

// Все предустановленные категории
class Categories {
  static List<TransactionCategory> get expenseCategories => const [
    TransactionCategory(
      id: 'food',
      name: 'Продукты',
      icon: Icons.restaurant,
      color: Colors.orange,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'transport',
      name: 'Транспорт',
      icon: Icons.directions_car,
      color: Colors.blue,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'entertainment',
      name: 'Развлечения',
      icon: Icons.movie,
      color: Colors.purple,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'shopping',
      name: 'Покупки',
      icon: Icons.shopping_bag,
      color: Colors.pink,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'bills',
      name: 'Коммуналка',
      icon: Icons.home,
      color: Colors.brown,
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'other_expense',
      name: 'Другое',
      icon: Icons.category,
      color: Colors.grey,
      type: TransactionType.expense,
    ),
  ];

  static List<TransactionCategory> get incomeCategories => const [
    TransactionCategory(
      id: 'salary',
      name: 'Зарплата',
      icon: Icons.attach_money,
      color: Colors.green,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'freelance',
      name: 'Фриланс',
      icon: Icons.work,
      color: Colors.cyan,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'gift',
      name: 'Подарок',
      icon: Icons.card_giftcard,
      color: Colors.amber,
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'other_income',
      name: 'Другое',
      icon: Icons.category,
      color: Colors.grey,
      type: TransactionType.income,
    ),
  ];

  static TransactionCategory getCategoryById(String id) {
    final all = [...expenseCategories, ...incomeCategories];
    return all.firstWhere((c) => c.id == id);
  }
}