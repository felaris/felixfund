// models/account.dart
class Account {
  final int? id;
  final String name;
  final double balance;
  final String type; // checking, savings, credit, etc.
  final String? details;
  final String? loginUsername;
  final String? loginPassword;
  final String? websiteUrl;
  final String? createdAt;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.type,
    this.details,
    this.loginUsername,
    this.loginPassword,
    this.websiteUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'balance': balance,
      'type': type,
      'details': details,
      'login_username': loginUsername,
      'login_password': loginPassword,
      'website_url': websiteUrl,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      type: map['type'],
      details: map['details'],
      loginUsername: map['login_username'],
      loginPassword: map['login_password'],
      websiteUrl: map['website_url'],
      createdAt: map['created_at'],
    );
  }
}

// models/transaction.dart
class Transaction {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String category;
  final String? description;
  final int? accountId;
  final String date;
  final bool isWant;
  final String? source; // For income sources

  Transaction({
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

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
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

// models/saving.dart
class Saving {
  final int? id;
  final String name;
  final double amount;
  final String? details;
  final String? createdAt;

  Saving({
    this.id,
    required this.name,
    required this.amount,
    this.details,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'amount': amount,
      'details': details,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  factory Saving.fromMap(Map<String, dynamic> map) {
    return Saving(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      details: map['details'],
      createdAt: map['created_at'],
    );
  }
}

// models/budget.dart
class Budget {
  final int? id;
  final String category;
  final double amount;
  final int month;
  final int year;

  Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      month: map['month'],
      year: map['year'],
    );
  }
}

// models/goal.dart
class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline;
  final String? createdAt;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      name: map['name'],
      targetAmount: map['target_amount'],
      currentAmount: map['current_amount'],
      deadline: map['deadline'],
      createdAt: map['created_at'],
    );
  }
}

// models/debt.dart
class Debt {
  final int? id;
  final String name;
  final double totalAmount;
  final double remainingAmount;
  final double? interestRate;
  final String? dueDate;
  final String? createdAt;

  Debt({
    this.id,
    required this.name,
    required this.totalAmount,
    required this.remainingAmount,
    this.interestRate,
    this.dueDate,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'total_amount': totalAmount,
      'remaining_amount': remainingAmount,
      'interest_rate': interestRate,
      'due_date': dueDate,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      name: map['name'],
      totalAmount: map['total_amount'],
      remainingAmount: map['remaining_amount'],
      interestRate: map['interest_rate'],
      dueDate: map['due_date'],
      createdAt: map['created_at'],
    );
  }
}