import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:felixfund/services/database_service.dart';
import 'package:felixfund/models/transaction.dart';
import 'package:felixfund/models/account.dart';
import 'package:felixfund/screens/accounts/accounts_screen.dart';
import 'package:felixfund/screens/transactions/transactions_screen.dart';
import 'package:felixfund/screens/savings/savings_screen.dart';
import 'package:felixfund/screens/budget/budget_screen.dart';
import 'package:felixfund/screens/goals/goals_screen.dart';
import 'package:felixfund/screens/debts/debts_screen.dart';
import 'package:felixfund/widgets/add_transaction_button.dart';
import 'package:felixfund/screens/settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');
  bool _isLoading = true;
  double _totalBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalSavings = 0;
  double _totalDebt = 0;
  List<TransactionModel> _recentTransactions = [];
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load financial data
      final totalBalance = await _databaseService.getTotalBalance();
      final totalIncome = await _databaseService.getTotalIncome();
      final totalExpense = await _databaseService.getTotalExpense();
      final totalSavings = await _databaseService.getTotalSavings();
      final totalDebt = await _databaseService.getTotalDebt();
      final recentTransactions = await _databaseService.getRecentTransactions(5);
      final accounts = await _databaseService.getAccounts();

      setState(() {
        _totalBalance = totalBalance;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _totalSavings = totalSavings;
        _totalDebt = totalDebt;
        _recentTransactions = recentTransactions;
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 30,
              height: 30,
            ),
            SizedBox(width: 8),
            Text('FelixFund'),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.settings),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => SettingsScreen()),
          //     );
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialOverview(),
              const SizedBox(height: 24),
              _buildAccountsOverview(),
              const SizedBox(height: 24),
              _buildSpendingChart(),
              const SizedBox(height: 24),
              _buildRecentTransactions(),
              const SizedBox(height: 24),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
      floatingActionButton: AddTransactionButton(
        onTransactionAdded: _loadData,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
          switch (index) {
            case 0:
            // Already on Dashboard
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TransactionsScreen()),
              ).then((_) => _loadData());
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BudgetScreen()),
              ).then((_) => _loadData());
              break;
    case 3:
    Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SettingsScreen()),
    );
    break;
    }

        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildFinancialItem(
              'Total Balance',
              _totalBalance,
              Icons.account_balance_wallet,
              Colors.blue,
            ),
            Divider(),
            _buildFinancialItem(
              'Monthly Income',
              _totalIncome,
              Icons.arrow_downward,
              Colors.green,
            ),
            Divider(),
            _buildFinancialItem(
              'Monthly Expenses',
              _totalExpense,
              Icons.arrow_upward,
              Colors.red,
            ),
            Divider(),
            _buildFinancialItem(
              'Total Savings',
              _totalSavings,
              Icons.savings,
              Colors.amber,
            ),
            Divider(),
            _buildFinancialItem(
              'Total Debt',
              _totalDebt,
              Icons.credit_card,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialItem(
      String title,
      double amount,
      IconData icon,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            currencyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsOverview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accounts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AccountsScreen()),
                    ).then((_) => _loadData());
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text('No accounts added yet.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _accounts.length > 3 ? 3 : _accounts.length,
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  return ListTile(
                    leading: Icon(
                      _getAccountIcon(account.type),
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(account.name),
                    subtitle: Text(account.type),
                    trailing: Text(
                      currencyFormatter.format(account.balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: account.balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'credit':
        return Icons.credit_card;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Widget _buildSpendingChart() {
    // Placeholder data for the chart
    // In a real app, you would calculate this from transaction data
    final List<PieChartSectionData> sections = [
      PieChartSectionData(
        value: 35,
        title: 'Housing',
        color: Colors.blue,
        radius: 80,
      ),
      PieChartSectionData(
        value: 20,
        title: 'Food',
        color: Colors.green,
        radius: 80,
      ),
      PieChartSectionData(
        value: 15,
        title: 'Transport',
        color: Colors.orange,
        radius: 80,
      ),
      PieChartSectionData(
        value: 10,
        title: 'Utilities',
        color: Colors.purple,
        radius: 80,
      ),
      PieChartSectionData(
        value: 20,
        title: 'Other',
        color: Colors.red,
        radius: 80,
      ),
    ];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TransactionsScreen()),
                    ).then((_) => _loadData());
                  },
                  child: Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text('No transactions yet.'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recentTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _recentTransactions[index];
                  final isIncome = transaction.type == 'income';

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(transaction.category),
                    subtitle: Text(
                      transaction.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'}${currencyFormatter.format(transaction.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(DateTime.parse(transaction.date)),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildQuickActionItem(
                  'Savings',
                  Icons.savings,
                  Colors.amber,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SavingsScreen()),
                    ).then((_) => _loadData());
                  },
                ),
                _buildQuickActionItem(
                  'Settings',
                  Icons.settings,
                  Colors.blueGrey,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsScreen()),
                    );
                  },
                ),
                _buildQuickActionItem(
                  'Debts',
                  Icons.credit_card,
                  Colors.purple,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DebtsScreen()),
                    ).then((_) => _loadData());
                  },
                ),
                _buildQuickActionItem(
                  'Goals',
                  Icons.flag,
                  Colors.green,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GoalsScreen()),
                    ).then((_) => _loadData());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}