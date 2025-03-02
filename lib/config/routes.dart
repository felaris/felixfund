import 'package:flutter/material.dart';
import 'package:felixfund/screens/auth/pin_screen.dart';
import 'package:felixfund/screens/dashboard/dashboard_screen.dart';
import 'package:felixfund/screens/accounts/accounts_screen.dart';
import 'package:felixfund/screens/transactions/transactions_screen.dart';
import 'package:felixfund/screens/budget/budget_screen.dart';
import 'package:felixfund/screens/savings/savings_screen.dart';
import 'package:felixfund/screens/goals/goals_screen.dart';
import 'package:felixfund/screens/debts/debts_screen.dart';
import 'package:felixfund/screens/settings/settings_screen.dart';

class AppRoutes {
  static const String pin = '/pin';
  static const String setupPin = '/setup-pin';
  static const String dashboard = '/dashboard';
  static const String accounts = '/accounts';
  static const String transactions = '/transactions';
  static const String budget = '/budget';
  static const String savings = '/savings';
  static const String goals = '/goals';
  static const String debts = '/debts';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    pin: (context) => PinScreen(),
    setupPin: (context) => SetupPinScreen(),
    dashboard: (context) => DashboardScreen(),
    accounts: (context) => AccountsScreen(),
    transactions: (context) => TransactionsScreen(),
    budget: (context) => BudgetScreen(),
    savings: (context) => SavingsScreen(),
    goals: (context) => GoalsScreen(),
    debts: (context) => DebtsScreen(),
    settings: (context) => SettingsScreen(),
  };
}