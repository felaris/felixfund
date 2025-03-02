import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:felixfund/models/saving.dart';
import 'package:felixfund/services/database_service.dart';

import '../../models/account.dart';

class SavingsScreen extends StatefulWidget {
  @override
  _SavingsScreenState createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');

  List<Saving> _savings = [];
  bool _isLoading = true;
  double _totalSavings = 0;

  @override
  void initState() {
    super.initState();
    _loadSavings();
  }

  Future<void> _loadSavings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final savings = await _databaseService.getSavings();
      final totalSavings = await _databaseService.getTotalSavings();

      setState(() {
        _savings = savings;
        _totalSavings = totalSavings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading savings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Savings'),
        backgroundColor: Color(0xFF2ECC71), // Emerald Green
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
      ))
          : Column(
        children: [
          _buildSavingsSummary(),
          Expanded(
            child: _savings.isEmpty
                ? _buildEmptySavings()
                : _buildSavingsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSavingModal(context);
        },
        backgroundColor: Color(0xFF2ECC71), // Emerald Green
        child: Icon(Icons.add),
        tooltip: 'Add Saving',
      ),
    );
  }

  Widget _buildSavingsSummary() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2ECC71), // Emerald Green
            Color(0xFF27AE60), // Darker Green
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Total Savings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              currencyFormatter.format(_totalSavings),
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_savings.length} Saving Account${_savings.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySavings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_savings.png', // Add this image to your assets
            width: 150,
            height: 150,
          ),
          SizedBox(height: 24),
          Text(
            'No Savings Accounts Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B263B), // Deep Navy Blue
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Start building your wealth by adding\nyour first savings account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddSavingModal(context);
            },
            icon: Icon(Icons.add),
            label: Text('Add Savings Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2ECC71), // Emerald Green
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _savings.length,
      itemBuilder: (context, index) {
        return _buildSavingCard(_savings[index]);
      },
    );
  }

  Widget _buildSavingCard(Saving saving) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showSavingDetails(saving);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2ECC71).withOpacity(0.1), // Light Green
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.savings,
                      color: Color(0xFF2ECC71), // Emerald Green
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saving.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1B263B), // Deep Navy Blue
                          ),
                        ),
                        if (saving.details != null && saving.details!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              saving.details!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(saving.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF2ECC71), // Emerald Green
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavingDetails(Saving saving) {
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Saving Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B263B), // Deep Navy Blue
                ),
              ),
              SizedBox(height: 16),
              _buildDetailRow('Name', saving.name),
              _buildDetailRow(
                'Amount',
                currencyFormatter.format(saving.amount),
                valueColor: Color(0xFF2ECC71), // Emerald Green
              ),
              if (saving.details != null && saving.details!.isNotEmpty)
                _buildDetailRow('Details', saving.details!),
              if (saving.createdAt != null)
                _buildDetailRow(
                  'Created',
                  DateFormat('MMMM dd, yyyy').format(DateTime.parse(saving.createdAt!)),
                ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editSaving(saving);
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2ECC71), // Emerald Green
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteSaving(saving);
                    },
                    icon: Icon(Icons.delete),
                    label: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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

  void _showAddSavingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SavingForm(
          onSavingAdded: _loadSavings,
        );
      },
    );
  }

  void _editSaving(Saving saving) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SavingForm(
          onSavingAdded: _loadSavings,
          saving: saving,
        );
      },
    );
  }

  void _deleteSaving(Saving saving) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Saving'),
          content: Text('Are you sure you want to delete this saving account?'),
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
                  await _databaseService.deleteSaving(saving.id!);
                  // Reload savings
                  _loadSavings();
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saving deleted successfully'),
                      backgroundColor: Color(0xFF2ECC71), // Emerald Green
                    ),
                  );
                } catch (e) {
                  print('Error deleting saving: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete saving'),
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

class SavingForm extends StatefulWidget {
  final Function onSavingAdded;
  final Saving? saving;

  const SavingForm({
    Key? key,
    required this.onSavingAdded,
    this.saving,
  }) : super(key: key);

  @override
  _SavingFormState createState() => _SavingFormState();
}

class _SavingFormState extends State<SavingForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  TextEditingController _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // If editing an existing saving, populate the form
    if (widget.saving != null) {
      _nameController.text = widget.saving!.name;
      _amountController.text = widget.saving!.amount.toString();
      _detailsController.text = widget.saving!.details ?? '';
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              widget.saving == null ? 'Add Saving Account' : 'Edit Saving Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B263B), // Deep Navy Blue
              ),
            ),
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Saving Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      prefixIcon: Icon(Icons.savings),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color(0xFF2ECC71), // Emerald Green
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the saving account';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Saving Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color(0xFF2ECC71), // Emerald Green
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the amount';
                      }
                      if (double.tryParse(value) == null || double.parse(value) < 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Details (Optional)
                  TextFormField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText: 'Details (Optional)',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Color(0xFF2ECC71), // Emerald Green
                          width: 2,
                        ),
                      ),
                      hintText: 'Additional information about this saving account',
                    ),
                    maxLines: 3,
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
                          widget.saving == null ? 'Add Saving Account' : 'Update Saving Account',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2ECC71), // Emerald Green
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
        final saving = Saving(
          id: widget.saving?.id,
          name: _nameController.text,
          amount: double.parse(_amountController.text),
          details: _detailsController.text.isEmpty ? null : _detailsController.text,
        );

        if (widget.saving == null) {
          // Add new saving
          await _databaseService.insertSaving(saving);
        } else {
          // Update existing saving
          await _databaseService.updateSaving(saving);
        }

        // Notify parent that saving was added/updated
        widget.onSavingAdded();

        // Close the form
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.saving == null
                  ? 'Saving account added successfully'
                  : 'Saving account updated successfully',
            ),
            backgroundColor: Color(0xFF2ECC71), // Emerald Green
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