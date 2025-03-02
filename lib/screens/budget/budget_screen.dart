import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:felixfund/models/budget.dart';
import 'package:felixfund/models/transaction.dart';
import 'package:felixfund/services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/account.dart';

class BudgetScreen extends StatefulWidget {
  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  List<Budget> _budgets = [];
  Map<String, double> _currentSpending = {};
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Predefined expense categories
  final List<String> _expenseCategories = [
    'Food', 'Housing', 'Transportation', 'Entertainment', 'Utilities',
    'Shopping', 'Health', 'Education', 'Personal', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load budget limits for the selected month
      final budgets = await _databaseService.getBudgets(_selectedMonth, _selectedYear);

      // Initialize budgets for categories that don't have one yet
      final budgetCategories = budgets.map((b) => b.category).toSet();
      for (final category in _expenseCategories) {
        if (!budgetCategories.contains(category)) {
          // Create a default budget with 0 amount
          budgets.add(Budget(
            category: category,
            amount: 0,
            month: _selectedMonth,
            year: _selectedYear,
          ));
        }
      }

      // Calculate current spending for each category
      final Map<String, double> currentSpending = {};
      for (final category in _expenseCategories) {
        // Get transactions for this category and month
        // In a real app, you would add a method to database_service.dart to get this data
        final transactions = await _getTransactionsByCategory(category);
        final total = transactions.fold<double>(
            0, (sum, transaction) => sum + transaction.amount);
        currentSpending[category] = total;
      }

      setState(() {
        _budgets = budgets;
        _currentSpending = currentSpending;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading budget data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // This is a placeholder for a real implementation that would query the database
  Future<List<TransactionModel>> _getTransactionsByCategory(String category) async {
    // In a real app, modify database_service.dart to add a method for this
    // For now, we'll return a placeholder
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectMonth,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),
            SizedBox(height: 24),
            _buildBudgetChart(),
            SizedBox(height: 24),
            _buildCategoryBudgetList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBudgetModal(context);
        },
        child: Icon(Icons.add),
        tooltip: 'Set Budget Limits',
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                setState(() {
                  if (_selectedMonth == 1) {
                    _selectedMonth = 12;
                    _selectedYear--;
                  } else {
                    _selectedMonth--;
                  }
                });
                _loadBudgetData();
              },
            ),
            Text(
              '${DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth))} ${_selectedYear}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              onPressed: () {
                setState(() {
                  if (_selectedMonth == 12) {
                    _selectedMonth = 1;
                    _selectedYear++;
                  } else {
                    _selectedMonth++;
                  }
                });
                _loadBudgetData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectMonth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedMonth = pickedDate.month;
        _selectedYear = pickedDate.year;
      });
      _loadBudgetData();
    }
  }

  Widget _buildBudgetChart() {
    // Calculate total budget and spending
    final totalBudget = _budgets.fold<double>(
        0, (sum, budget) => sum + budget.amount);
    final totalSpending = _currentSpending.values.fold<double>(
        0, (sum, spending) => sum + spending);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Budget Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBudgetInfoCard(
                  'Total Budget',
                  totalBudget,
                  Colors.blue,
                  Icons.account_balance_wallet,
                ),
                _buildBudgetInfoCard(
                  'Total Spent',
                  totalSpending,
                  totalSpending > totalBudget ? Colors.red : Colors.green,
                  Icons.shopping_cart,
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Budget Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            if (totalBudget == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'Set your budget limits to see the progress',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              LinearProgressIndicator(
                value: totalSpending / totalBudget,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  totalSpending > totalBudget ? Colors.red : Colors.green,
                ),
                minHeight: 20,
              ),
            SizedBox(height: 8),
            Text(
              '${(totalSpending / totalBudget * 100).toStringAsFixed(1)}% of budget used',
              style: TextStyle(
                color: totalSpending > totalBudget ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInfoCard(
      String title,
      double amount,
      Color color,
      IconData icon,
      ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            currencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _budgets.length,
              itemBuilder: (context, index) {
                final budget = _budgets[index];
                final spent = _currentSpending[budget.category] ?? 0;
                final progress = budget.amount > 0 ? spent / budget.amount : 0;
                final isOverBudget = spent > budget.amount && budget.amount > 0;

                return _buildBudgetItem(
                  budget,
                  spent,
                  progress.toDouble(),
                  isOverBudget,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(
      Budget budget,
      double spent,
      double progress,
      bool isOverBudget,
      ) {
    return InkWell(
      onTap: () {
        _showEditBudgetModal(context, budget);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget.category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${currencyFormatter.format(spent)} / ${currencyFormatter.format(budget.amount)}',
                  style: TextStyle(
                    color: isOverBudget ? Colors.red : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : Colors.green,
              ),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BudgetForm(
          onBudgetAdded: _loadBudgetData,
          month: _selectedMonth,
          year: _selectedYear,
          categories: _expenseCategories,
        );
      },
    );
  }

  void _showEditBudgetModal(BuildContext context, Budget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BudgetForm(
          onBudgetAdded: _loadBudgetData,
          budget: budget,
          month: _selectedMonth,
          year: _selectedYear,
          categories: _expenseCategories,
        );
      },
    );
  }
}

class BudgetForm extends StatefulWidget {
  final Function onBudgetAdded;
  final Budget? budget;
  final int month;
  final int year;
  final List<String> categories;

  const BudgetForm({
    Key? key,
    required this.onBudgetAdded,
    this.budget,
    required this.month,
    required this.year,
    required this.categories,
  }) : super(key: key);

  @override
  _BudgetFormState createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  TextEditingController _amountController = TextEditingController();
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();

    // If editing an existing budget, populate the form
    if (widget.budget != null) {
      _selectedCategory = widget.budget!.category;
      _amountController.text = widget.budget!.amount.toString();
    } else {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              widget.budget == null ? 'Set Budget Limit' : 'Edit Budget Limit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'For ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    items: widget.categories
                        .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                        .toList(),
                    onChanged: widget.budget != null
                        ? null // Disable changing category when editing
                        : (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Budget Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Budget Amount',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a budget amount';
                      }
                      if (double.tryParse(value) == null || double.parse(value) < 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          widget.budget == null ? 'Set Budget' : 'Update Budget',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final budget = Budget(
          id: widget.budget?.id,
          category: _selectedCategory,
          amount: double.parse(_amountController.text),
          month: widget.month,
          year: widget.year,
        );

        // Add or update budget
        await _databaseService.insertBudget(budget);

        // Notify parent that budget was added/updated
        widget.onBudgetAdded();

        // Close the form
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.budget == null
                  ? 'Budget set successfully'
                  : 'Budget updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error saving budget: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save budget'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}