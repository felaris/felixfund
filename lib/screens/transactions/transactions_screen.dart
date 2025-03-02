import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:felixfund/models/transaction.dart';
import 'package:felixfund/services/database_service.dart';
import 'package:felixfund/widgets/add_transaction_button.dart';

import '../../models/account.dart';

class TransactionsScreen extends StatefulWidget {
  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'all';
            break;
          case 1:
            _selectedFilter = 'income';
            break;
          case 2:
            _selectedFilter = 'expense';
            break;
        }
      });
      _filterTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _databaseService.getTransactions();

      setState(() {
        _transactions = transactions;
        _filterTransactions();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTransactions() {
    setState(() {
      if (_selectedFilter == 'all') {
        _filteredTransactions = _transactions.where((t) {
          return t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (t.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      } else {
        _filteredTransactions = _transactions.where((t) {
          return t.type == _selectedFilter &&
              (t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (t.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase()));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterTransactions();
              },
            ),
          ),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
              child: Text(
                'No transactions found.',
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: _filteredTransactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionItem(_filteredTransactions[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AddTransactionButton(
        onTransactionAdded: _loadTransactions,
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isIncome = transaction.type == 'income';
    final date = DateTime.parse(transaction.date);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
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
        title: Text(
          transaction.category,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null && transaction.description!.isNotEmpty)
              Text(transaction.description!),
            Text(
              DateFormat('MMMM dd, yyyy').format(date),
              style: TextStyle(color: Colors.grey),
            ),
            if (isIncome && transaction.source != null && transaction.source!.isNotEmpty)
              Text(
                'Source: ${transaction.source}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            if (!isIncome && transaction.isWant)
              Chip(
                label: Text('Want'),
                backgroundColor: Colors.amber.withOpacity(0.2),
                labelStyle: TextStyle(color: Colors.amber[800]),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${currencyFormatter.format(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        onTap: () {
          _showTransactionDetails(transaction as Transaction);
        },
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
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
                'Transaction Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildDetailRow(
                'Type',
                transaction.type.toUpperCase(),
                transaction.type == 'income' ? Colors.green : Colors.red,
              ),
              _buildDetailRow(
                'Category',
                transaction.category,
                null,
              ),
              _buildDetailRow(
                'Amount',
                currencyFormatter.format(transaction.amount),
                null,
              ),
              _buildDetailRow(
                'Date',
                DateFormat('MMMM dd, yyyy').format(DateTime.parse(transaction.date)),
                null,
              ),
              if (transaction.description != null && transaction.description!.isNotEmpty)
                _buildDetailRow(
                  'Description',
                  transaction.description!,
                  null,
                ),
              if (transaction.type == 'income' && transaction.source != null && transaction.source!.isNotEmpty)
                _buildDetailRow(
                  'Source',
                  transaction.source!,
                  null,
                ),
              if (transaction.type == 'expense')
                _buildDetailRow(
                  'Want vs Need',
                  transaction.isWant ? 'Want' : 'Need',
                  transaction.isWant ? Colors.amber[800] : Colors.blue,
                ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editTransaction(transaction);
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteTransaction(transaction);
                    },
                    icon: Icon(Icons.delete),
                    label: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editTransaction(Transaction transaction) {
    // Navigate to edit transaction screen
    // Implementation will be added later
  }

  void _deleteTransaction(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _databaseService.deleteTransaction(transaction.id!);
                  // Reload transactions
                  _loadTransactions();
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Transaction deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error deleting transaction: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete transaction'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}