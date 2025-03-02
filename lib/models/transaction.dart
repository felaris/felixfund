// models/transaction.dart
class TransactionModel {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String? description;
  final int? accountId;
  final String date;
  final bool isWant;
  final String? source; // For income sources

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    this.accountId,
    required this.date,
    this.isWant = false,
    this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'account_id': accountId,
      'date': date,
      'is_want': isWant ? 1 : 0,
      'source': source,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      description: map['description'],
      accountId: map['account_id'],
      date: map['date'],
      isWant: map['is_want'] == 1,
      source: map['source'],
    );
  }
}