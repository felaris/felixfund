import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:felixfund/models/transaction.dart';
import 'package:felixfund/models/account.dart';
import 'package:felixfund/services/database_service.dart';

class AddTransactionButton extends StatelessWidget {
  final Function onTransactionAdded;

  const AddTransactionButton({
    Key? key,
    required this.onTransactionAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _showAddTransactionModal(context);
      },
      child: Icon(Icons.add),
      tooltip: 'Add Transaction',
    );
  }

  void _showAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddTransactionForm(
          onTransactionAdded: onTransactionAdded,
        );
      },
    );
  }
}

class AddTransactionForm extends StatefulWidget {
  final Function onTransactionAdded;
  final Transaction? transaction; // For editing existing transaction

  const AddTransactionForm({
    Key? key,
    required this.onTransactionAdded,
    this.transaction,
  }) : super(key: key);

  @override
  _AddTransactionFormState createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  String _type = 'expense'; // Default type
  TextEditingController _amountController = TextEditingController();
  TextEditingController _categoryController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _sourceController = TextEditingController();
  DateTime _date = DateTime.now();
  int? _selectedAccountId;
  bool _isWant = false;

  List<Account> _accounts = [];
  bool _isLoading = true;

  // Predefined categories
  final List<String> _expenseCategories = [
    'Food', 'Housing', 'Transportation', 'Entertainment', 'Utilities',
    'Shopping', 'Health', 'Education', 'Personal', 'Other'
  ];

  final List<String> _incomeCategories = [
    'Salary', 'Freelance', 'Business', 'Investment', 'Gift',
    'Refund', 'Bonus', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();

    // If editing an existing transaction, populate the form
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _amountController.text = widget.transaction!.amount.toString();
      _categoryController.text = widget.transaction!.category;
      _descriptionController.text = widget.transaction!.description ?? '';
      _sourceController.text = widget.transaction!.source ?? '';
      _date = DateTime.parse(widget.transaction!.date);
      _selectedAccountId = widget.transaction!.accountId;
      _isWant = widget.transaction!.isWant;
    }
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _databaseService.getAccounts();
      setState(() {
        _accounts = accounts;
        if (_accounts.isNotEmpty && _selectedAccountId == null) {
          _selectedAccountId = _accounts.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() {
        _isLoading = false;
      });
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
              widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Transaction Type Selector
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Expense'),
                            value: 'expense',
                            groupValue: _type,
                            onChanged: (value) {
                              setState(() {
                                _type = value!;
                                _categoryController.clear();
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Income'),
                            value: 'income',
                            groupValue: _type,
                            onChanged: (value) {
                              setState(() {
                                _type = value!;
                                _categoryController.clear();
                                _isWant = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Category Field with Dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                      items: (_type == 'expense' ? _expenseCategories : _incomeCategories)
                          .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoryController.text = value!;
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

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            _date = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('MMMM dd, yyyy').format(_date),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Account Dropdown
                    if (_accounts.isNotEmpty)
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Account',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedAccountId,
                        items: _accounts
                            .map((account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccountId = value;
                          });
                        },
                      )
                    else
                      TextButton(
                        onPressed: () {
                          // Navigate to add account screen
                          // Will be implemented later
                        },
                        child: Text('+ Add an account first'),
                      ),
                    SizedBox(height: 16),

                    // Additional fields based on transaction type
                    if (_type == 'income')
                      TextFormField(
                        controller: _sourceController,
                        decoration: InputDecoration(
                          labelText: 'Source (Optional)',
                          prefixIcon: Icon(Icons.source),
                          border: OutlineInputBorder(),
                          hintText: 'Where did this income come from?',
                        ),
                      )
                    else
                    // Want vs Need checkbox for expenses
                      CheckboxListTile(
                        title: Text('This is a "want" (discretionary purchase)'),
                        value: _isWant,
                        onChanged: (value) {
                          setState(() {
                            _isWant = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
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
                            widget.transaction == null ? 'Add Transaction' : 'Update Transaction',
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
        final transaction = TransactionModel(
          id: widget.transaction?.id,
          amount: double.parse(_amountController.text),
          type: _type,
          category: _categoryController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          accountId: _selectedAccountId,
          date: _date.toIso8601String(),
          isWant: _type == 'expense' ? _isWant : false,
          source: _type == 'income' && _sourceController.text.isNotEmpty ? _sourceController.text : null,
        );

        if (widget.transaction == null) {
          // Add new transaction
          await _databaseService.insertTransaction(transaction);
        } else {
          // Update existing transaction
          await _databaseService.updateTransaction(transaction);
        }

        // Update account balance if needed (simplified version)
        // A more sophisticated app might have a separate service for this

        // Notify parent that transaction was added/updated
        widget.onTransactionAdded();

        // Close the form
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.transaction == null
                  ? 'Transaction added successfully'
                  : 'Transaction updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error saving transaction: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save transaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}