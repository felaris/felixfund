import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:felixfund/models/debt.dart';
import 'package:felixfund/services/database_service.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/account.dart';

class DebtsScreen extends StatefulWidget {
  @override
  _DebtsScreenState createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  List<Debt> _debts = [];
  bool _isLoading = true;
  double _totalDebt = 0;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final debts = await _databaseService.getDebts();
      final totalDebt = await _databaseService.getTotalDebt();

      setState(() {
        _debts = debts;
        _totalDebt = totalDebt;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading debts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debt Tracker'),
        backgroundColor: Color(0xFF1B263B), // Deep Navy Blue
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
      ))
          : Column(
        children: [
          _buildDebtSummary(),
          if (_debts.isNotEmpty) _buildDebtChart(),
          Expanded(
            child: _debts.isEmpty
                ? _buildEmptyDebt()
                : _buildDebtList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDebtModal(context);
        },
        backgroundColor: Color(0xFF2ECC71), // Emerald Green
        child: Icon(Icons.add),
        tooltip: 'Add Debt',
      ),
    );
  }

  Widget _buildDebtSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1B263B), // Deep Navy Blue
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Debt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(_totalDebt),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF2ECC71).withOpacity(0.2), // Light Green
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_debts.length} Debt${_debts.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Color(0xFF2ECC71), // Emerald Green
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_debts.isNotEmpty) ...[
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Highest Interest',
                  _getHighestInterestDebt(),
                  Color(0xFFF4C542), // Soft Gold
                ),
                _buildSummaryItem(
                  'Next Payment',
                  _getNextPaymentDate(),
                  Colors.white,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getHighestInterestDebt() {
    if (_debts.isEmpty) return 'None';

    Debt highestInterestDebt = _debts.reduce((a, b) {
      final aRate = a.interestRate ?? 0;
      final bRate = b.interestRate ?? 0;
      return aRate > bRate ? a : b;
    });

    final interestRate = highestInterestDebt.interestRate ?? 0;
    return '${interestRate.toStringAsFixed(1)}%';
  }

  String _getNextPaymentDate() {
    if (_debts.isEmpty) return 'None';

    // Filter debts with due dates and find the closest one
    final debtsWithDueDates = _debts.where((debt) => debt.dueDate != null).toList();
    if (debtsWithDueDates.isEmpty) return 'Not set';

    debtsWithDueDates.sort((a, b) {
      final aDate = DateTime.parse(a.dueDate!);
      final bDate = DateTime.parse(b.dueDate!);
      return aDate.compareTo(bDate);
    });

    final nextDueDate = DateTime.parse(debtsWithDueDates.first.dueDate!);
    final now = DateTime.now();
    final difference = nextDueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      return DateFormat('MMM dd').format(nextDueDate);
    }
  }

  Widget _buildDebtChart() {
    // Prepare data for the chart
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Color(0xFF2ECC71), // Emerald Green
      Color(0xFF3498DB), // Blue
      Color(0xFFF4C542), // Soft Gold
      Color(0xFF9B59B6), // Purple
      Color(0xFFE74C3C), // Red
      Color(0xFF1ABC9C), // Turquoise
      Color(0xFFE67E22), // Orange
    ];

    for (int i = 0; i < _debts.length; i++) {
      final debt = _debts[i];
      final percentage = (debt.remainingAmount / _totalDebt) * 100;

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: debt.remainingAmount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      height: 220,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debt Breakdown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),
                ..._debts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final debt = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            debt.name,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDebt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_debt.png', // Add this image to your assets
            width: 180,
            height: 180,
          ),
          SizedBox(height: 24),
          Text(
            'No Debts Added Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B263B), // Deep Navy Blue
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Add your debts to track progress and plan your repayment strategy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddDebtModal(context);
            },
            icon: Icon(Icons.add),
            label: Text('Add Debt'),
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

  Widget _buildDebtList() {
    // Sort debts: highest interest rate first
    final sortedDebts = List<Debt>.from(_debts);
    sortedDebts.sort((a, b) {
      final aRate = a.interestRate ?? 0;
      final bRate = b.interestRate ?? 0;
      return bRate.compareTo(aRate);
    });

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedDebts.length,
      itemBuilder: (context, index) {
        return _buildDebtCard(sortedDebts[index]);
      },
    );
  }

  Widget _buildDebtCard(Debt debt) {
    // Calculate progress (how much has been paid)
    final paidAmount = debt.totalAmount - debt.remainingAmount;
    final progressPercentage = debt.totalAmount > 0
        ? (paidAmount / debt.totalAmount)
        : 0.0;

    // Format due date
    String dueString = '';
    if (debt.dueDate != null) {
      final dueDate = DateTime.parse(debt.dueDate!);
      final now = DateTime.now();
      final difference = dueDate.difference(now).inDays;

      if (difference < 0) {
        dueString = 'Overdue';
      } else if (difference == 0) {
        dueString = 'Due today';
      } else if (difference == 1) {
        dueString = 'Due tomorrow';
      } else {
        dueString = 'Due in $difference days';
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showDebtDetails(debt);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1B263B), // Deep Navy Blue
                          ),
                        ),
                        SizedBox(height: 4),
                        if (debt.dueDate != null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: DateTime.parse(debt.dueDate!).isBefore(DateTime.now())
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                dueString,
                                style: TextStyle(
                                  color: DateTime.parse(debt.dueDate!).isBefore(DateTime.now())
                                      ? Colors.red
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF1B263B).withOpacity(0.1), // Light Navy
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      debt.interestRate != null
                          ? '${debt.interestRate!.toStringAsFixed(1)}%'
                          : 'No interest',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B263B), // Deep Navy Blue
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(debt.remainingAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1B263B), // Deep Navy Blue
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(debt.totalAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF2ECC71), // Emerald Green
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${(progressPercentage * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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

  void _showDebtDetails(Debt debt) {
    // Calculate progress
    final paidAmount = debt.totalAmount - debt.remainingAmount;
    final progressPercentage = debt.totalAmount > 0
        ? (paidAmount / debt.totalAmount)
        : 0.0;

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
                'Debt Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B263B), // Deep Navy Blue
                ),
              ),
              SizedBox(height: 16),
              _buildDetailRow('Name', debt.name),
              _buildDetailRow(
                'Total Amount',
                currencyFormatter.format(debt.totalAmount),
              ),
              _buildDetailRow(
                'Remaining',
                currencyFormatter.format(debt.remainingAmount),
                valueColor: Color(0xFF1B263B), // Deep Navy Blue
              ),
              _buildDetailRow(
                'Paid',
                currencyFormatter.format(paidAmount),
                valueColor: Color(0xFF2ECC71), // Emerald Green
              ),
              if (debt.interestRate != null)
                _buildDetailRow(
                  'Interest Rate',
                  '${debt.interestRate!.toStringAsFixed(1)}%',
                  valueColor: Color(0xFFF4C542), // Soft Gold
                ),
              if (debt.dueDate != null)
                _buildDetailRow(
                  'Due Date',
                  DateFormat('MMMM dd, yyyy').format(DateTime.parse(debt.dueDate!)),
                  valueColor: DateTime.parse(debt.dueDate!).isBefore(DateTime.now())
                      ? Colors.red
                      : null,
                ),
              _buildDetailRow(
                'Progress',
                '${(progressPercentage * 100).toInt()}% paid off',
                valueColor: Color(0xFF2ECC71), // Emerald Green
              ),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF2ECC71), // Emerald Green
                  ),
                  minHeight: 10,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateDebtPayment(debt);
                    },
                    icon: Icon(Icons.payment),
                    label: Text('Record Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF4C542), // Soft Gold
                      foregroundColor: Color(0xFF1B263B), // Deep Navy Blue
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editDebt(debt);
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2ECC71), // Emerald Green
                      foregroundColor: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteDebt(debt);
                    },
                    icon: Icon(Icons.delete),
                    color: Colors.red,
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

  void _updateDebtPayment(Debt debt) {
    final TextEditingController _paymentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current remaining: ${currencyFormatter.format(debt.remainingAmount)}',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _paymentController,
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
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
                // Validate input
                final amount = double.tryParse(_paymentController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (amount > debt.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment amount cannot exceed remaining balance'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Update debt remaining amount
                final updatedDebt = Debt(
                  id: debt.id,
                  name: debt.name,
                  totalAmount: debt.totalAmount,
                  remainingAmount: debt.remainingAmount - amount,
                  interestRate: debt.interestRate,
                  dueDate: debt.dueDate,
                  createdAt: debt.createdAt,
                );

                try {
                  await _databaseService.updateDebt(updatedDebt);
                  _loadDebts();
                  Navigator.pop(context);

                  // Show congrats dialog if debt is paid off
                  if (updatedDebt.remainingAmount == 0) {
                    _showDebtPaidOffCongratulations(debt.name);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment recorded successfully'),
                        backgroundColor: Color(0xFF2ECC71), // Emerald Green
                      ),
                    );
                  }
                } catch (e) {
                  print('Error updating debt payment: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to record payment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Record'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF2ECC71), // Emerald Green
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDebtPaidOffCongratulations(String debtName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Debt Paid Off! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF2ECC71), // Emerald Green
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Congratulations! You\'ve completely paid off:',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                debtName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1B263B), // Deep Navy Blue
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'That\'s a huge financial achievement!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Thanks!'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF2ECC71), // Emerald Green
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddDebtModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DebtForm(
          onDebtAdded: _loadDebts,
        );
      },
    );
  }

  void _editDebt(Debt debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DebtForm(
          onDebtAdded: _loadDebts,
          debt: debt,
        );
      },
    );
  }

  void _deleteDebt(Debt debt) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Debt'),
          content: Text('Are you sure you want to delete this debt?'),
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
                  await _databaseService.deleteDebt(debt.id!);
                  // Reload debts
                  _loadDebts();
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Debt deleted successfully'),
                      backgroundColor: Color(0xFF2ECC71), // Emerald Green
                    ),
                  );
                } catch (e) {
                  print('Error deleting debt: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete debt'),
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

class DebtForm extends StatefulWidget {
  final Function onDebtAdded;
  final Debt? debt;

  const DebtForm({
    Key? key,
    required this.onDebtAdded,
    this.debt,
  }) : super(key: key);

  @override
  _DebtFormState createState() => _DebtFormState();
}

class _DebtFormState extends State<DebtForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _totalAmountController = TextEditingController();
  TextEditingController _remainingAmountController = TextEditingController();
  TextEditingController _interestRateController = TextEditingController();
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();

    // If editing an existing debt, populate the form
    if (widget.debt != null) {
      _nameController.text = widget.debt!.name;
      _totalAmountController.text = widget.debt!.totalAmount.toString();
      _remainingAmountController.text = widget.debt!.remainingAmount.toString();
      if (widget.debt!.interestRate != null) {
        _interestRateController.text = widget.debt!.interestRate.toString();
      }
      if (widget.debt!.dueDate != null) {
        _dueDate = DateTime.parse(widget.debt!.dueDate!);
      }
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
              widget.debt == null ? 'Add Debt' : 'Edit Debt',
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
                  // Debt Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Debt Name',
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
                      hintText: 'e.g., Credit Card, Student Loan, Mortgage',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the debt';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Total Amount
                  TextFormField(
                    controller: _totalAmountController,
                    decoration: InputDecoration(
                      labelText: 'Total Amount',
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
                        return 'Please enter the total amount';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Remaining Amount
                  TextFormField(
                    controller: _remainingAmountController,
                    decoration: InputDecoration(
                      labelText: 'Remaining Amount',
                      prefixIcon: Icon(Icons.account_balance_wallet),
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
                        return 'Please enter the remaining amount';
                      }

                      final remainingAmount = double.tryParse(value);
                      if (remainingAmount == null || remainingAmount < 0) {
                        return 'Please enter a valid amount';
                      }

                      final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;
                      if (remainingAmount > totalAmount) {
                        return 'Remaining cannot exceed total amount';
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Interest Rate (Optional)
                  TextFormField(
                    controller: _interestRateController,
                    decoration: InputDecoration(
                      labelText: 'Interest Rate % (Optional)',
                      prefixIcon: Icon(Icons.percent),
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
                      hintText: 'e.g., 3.5',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final interestRate = double.tryParse(value);
                        if (interestRate == null || interestRate < 0) {
                          return 'Please enter a valid interest rate';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Due Date Picker (Optional)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now().add(Duration(days: 30)),
                        firstDate: DateTime.now().subtract(Duration(days: 365)), // Allow past dates for already overdue debts
                        lastDate: DateTime.now().add(Duration(days: 365 * 10)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Color(0xFF2ECC71), // Emerald Green
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        setState(() {
                          _dueDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Date (Optional)',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: _dueDate != null
                            ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _dueDate = null;
                            });
                          },
                        )
                            : null,
                      ),
                      child: Text(
                        _dueDate == null
                            ? 'No due date set'
                            : DateFormat('MMMM dd, yyyy').format(_dueDate!),
                      ),
                    ),
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
                          widget.debt == null ? 'Add Debt' : 'Update Debt',
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
        final totalAmount = double.parse(_totalAmountController.text);
        final remainingAmount = double.parse(_remainingAmountController.text);

        // Parse interest rate if provided
        double? interestRate;
        if (_interestRateController.text.isNotEmpty) {
          interestRate = double.parse(_interestRateController.text);
        }

        final debt = Debt(
          id: widget.debt?.id,
          name: _nameController.text,
          totalAmount: totalAmount,
          remainingAmount: remainingAmount,
          interestRate: interestRate,
          dueDate: _dueDate?.toIso8601String(),
        );

        if (widget.debt == null) {
          // Add new debt
          await _databaseService.insertDebt(debt);
        } else {
          // Update existing debt
          await _databaseService.updateDebt(debt);
        }

        // Notify parent that debt was added/updated
        widget.onDebtAdded();

        // Close the form
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.debt == null
                  ? 'Debt added successfully'
                  : 'Debt updated successfully',
            ),
            backgroundColor: Color(0xFF2ECC71), // Emerald Green
          ),
        );
      } catch (e) {
        print('Error saving debt: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save debt'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}