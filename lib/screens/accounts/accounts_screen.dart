import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:felixfund/models/account.dart';
import 'package:felixfund/services/database_service.dart';

class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _databaseService.getAccounts();

      setState(() {
        _accounts = accounts;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('My Accounts'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: _accounts.length,
        itemBuilder: (context, index) {
          return _buildAccountCard(_accounts[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddAccountModal(context);
        },
        child: Icon(Icons.add),
        tooltip: 'Add Account',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No accounts added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first account by tapping the + button',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddAccountModal(context);
            },
            icon: Icon(Icons.add),
            label: Text('Add Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    Color balanceColor = account.balance >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showAccountDetails(account);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getAccountIcon(account.type),
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        account.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currencyFormatter.format(account.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                account.type.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              if (account.details != null && account.details!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  account.details!,
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
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
      case 'cash':
        return Icons.money;
      default:
        return Icons.account_balance_wallet;
    }
  }

  void _showAccountDetails(Account account) {
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
                'Account Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildDetailRow('Name', account.name),
              _buildDetailRow('Type', account.type),
              _buildDetailRow(
                'Balance',
                currencyFormatter.format(account.balance),
                valueColor: account.balance >= 0 ? Colors.green : Colors.red,
              ),
              if (account.details != null && account.details!.isNotEmpty)
                _buildDetailRow('Details', account.details!),
              if (account.loginUsername != null && account.loginUsername!.isNotEmpty)
                _buildDetailRow('Username', account.loginUsername!),
              if (account.websiteUrl != null && account.websiteUrl!.isNotEmpty)
                _buildDetailRow('Website', account.websiteUrl!),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editAccount(account);
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
                      _deleteAccount(account);
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

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
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

  void _showAddAccountModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AccountForm(
          onAccountAdded: _loadAccounts,
        );
      },
    );
  }

  void _editAccount(Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AccountForm(
          onAccountAdded: _loadAccounts,
          account: account,
        );
      },
    );
  }

  void _deleteAccount(Account account) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete this account? This will remove all associated transactions.'
          ),
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
                  await _databaseService.deleteAccount(account.id!);
                  // Reload accounts
                  _loadAccounts();
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error deleting account: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account'),
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

class AccountForm extends StatefulWidget {
  final Function onAccountAdded;
  final Account? account; // For editing existing account

  const AccountForm({
    Key? key,
    required this.onAccountAdded,
    this.account,
  }) : super(key: key);

  @override
  _AccountFormState createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _balanceController = TextEditingController();
  TextEditingController _detailsController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _websiteController = TextEditingController();

  String _type = 'checking'; // Default type
  bool _isPasswordVisible = false;

  // Account types
  final List<String> _accountTypes = [
    'Checking', 'Savings', 'Credit', 'Investment', 'Cash', 'Other'
  ];

  @override
  void initState() {
    super.initState();

    // If editing an existing account, populate the form
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _type = widget.account!.type;
      _detailsController.text = widget.account!.details ?? '';
      _usernameController.text = widget.account!.loginUsername ?? '';
      _passwordController.text = widget.account!.loginPassword ?? '';
      _websiteController.text = widget.account!.websiteUrl ?? '';
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
              widget.account == null ? 'Add Account' : 'Edit Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Account Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      prefixIcon: Icon(Icons.account_balance),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the account';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Account Type
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Account Type',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    value: _type.isEmpty ? _accountTypes.first.toLowerCase() : _type,
                    items: _accountTypes
                        .map((type) => DropdownMenuItem(
                      value: type.toLowerCase(),
                      child: Text(type),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _type = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select an account type';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Account Balance
                  TextFormField(
                    controller: _balanceController,
                    decoration: InputDecoration(
                      labelText: 'Current Balance',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the current balance';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Account Details (Optional)
                  TextFormField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText: 'Details (Optional)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                      hintText: 'Additional notes about this account',
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 16),

                  // Login Credentials (Optional)
                  ExpansionTile(
                    title: Text('Login Information (Optional)'),
                    subtitle: Text('Securely store your credentials'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 16.0,
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username/Email',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _websiteController,
                              decoration: InputDecoration(
                                labelText: 'Website URL',
                                prefixIcon: Icon(Icons.link),
                                border: OutlineInputBorder(),
                                hintText: 'e.g., https://www.bankwebsite.com',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          widget.account == null ? 'Add Account' : 'Update Account',
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
        final account = Account(
          id: widget.account?.id,
          name: _nameController.text,
          balance: double.parse(_balanceController.text),
          type: _type,
          details: _detailsController.text.isEmpty ? null : _detailsController.text,
          loginUsername: _usernameController.text.isEmpty ? null : _usernameController.text,
          loginPassword: _passwordController.text.isEmpty ? null : _passwordController.text,
          websiteUrl: _websiteController.text.isEmpty ? null : _websiteController.text,
        );

        if (widget.account == null) {
          // Add new account
          await _databaseService.insertAccount(account);
        } else {
          // Update existing account
          await _databaseService.updateAccount(account);
        }

        // Notify parent that account was added/updated
        widget.onAccountAdded();

        // Close the form
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.account == null
                  ? 'Account added successfully'
                  : 'Account updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error saving account: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}