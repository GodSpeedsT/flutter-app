import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isExpense;
  final String? note;
  final String? receiptImagePath;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isExpense,
    this.note,
    this.receiptImagePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'isExpense': isExpense,
        'note': note,
        'receiptImagePath': receiptImagePath,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        category: json['category'],
        date: DateTime.parse(json['date']),
        isExpense: json['isExpense'],
        note: json['note'],
        receiptImagePath: json['receiptImagePath'],
      );

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    bool? isExpense,
    String? note,
    String? receiptImagePath,
  }) =>
      Transaction(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        date: date ?? this.date,
        isExpense: isExpense ?? this.isExpense,
        note: note ?? this.note,
        receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      );
}

class Budget {
  final String id;
  final String category;
  final double limit;
  final DateTime month;

  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'limit': limit,
        'month': month.toIso8601String(),
      };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'],
        category: json['category'],
        limit: (json['limit'] as num).toDouble(),
        month: DateTime.parse(json['month']),
      );
}

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  double currentAmount;
  final DateTime targetDate;
  final Color color;
  final IconData icon;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.color,
    required this.icon,
  });

  double get progress =>
      currentAmount / targetAmount > 1 ? 1 : currentAmount / targetAmount;
  double get remaining => targetAmount - currentAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate.toIso8601String(),
        'colorValue': color.value,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
        id: json['id'],
        title: json['title'],
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        targetDate: DateTime.parse(json['targetDate']),
        color: Color(json['colorValue']),
        icon: IconData(
          json['iconCodePoint'],
          fontFamily: json['iconFontFamily'] ?? 'MaterialIcons',
        ),
      );
}

class OcrScanResult {
  final String? storeName;
  final double? totalAmount;
  final DateTime? date;
  final List<OcrLineItem> items;
  final String rawText;

  OcrScanResult({
    this.storeName,
    this.totalAmount,
    this.date,
    required this.items,
    required this.rawText,
  });
}

class OcrLineItem {
  final String name;
  final double? price;
  final int? quantity;

  OcrLineItem({required this.name, this.price, this.quantity});
}