import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:felixfund/models/goal.dart';
import 'package:felixfund/services/database_service.dart';

import '../../models/account.dart';

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final currencyFormatter = NumberFormat.currency(locale: 'en_GH', symbol: 'GH₵');

  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await _databaseService.getGoals();

      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Goals'),
        backgroundColor: Color(0xFF2ECC71), // Emerald Green
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
      ))
          : Column(
        children: [
          _buildGoalsHeader(),
          Expanded(
            child: _goals.isEmpty
                ? _buildEmptyGoals()
                : _buildGoalsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddGoalModal(context);
        },
        backgroundColor: Color(0xFF2ECC71), // Emerald Green
        child: Icon(Icons.add),
        tooltip: 'Add Goal',
      ),
    );
  }

  Widget _buildGoalsHeader() {
    // Count completed goals
    final completedGoals = _goals.where((goal) =>
    goal.currentAmount >= goal.targetAmount).length;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1B263B), // Deep Navy Blue
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Goals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _goals.isEmpty
                    ? 'No goals set yet'
                    : '$completedGoals of ${_goals.length} goals completed',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _goals.isEmpty
                  ? Colors.grey
                  : Color(0xFFF4C542), // Soft Gold
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _goals.isEmpty
                    ? '0%'
                    : '${((completedGoals / _goals.length) * 100).toInt()}%',
                style: TextStyle(
                  color: Color(0xFF1B263B), // Deep Navy Blue
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoals() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_goals.png', // Add this image to your assets
            width: 180,
            height: 180,
          ),
          SizedBox(height: 24),
          Text(
            'No Financial Goals Yet',
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
              'Set clear financial goals to stay motivated and track your progress',
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
              _showAddGoalModal(context);
            },
            icon: Icon(Icons.add),
            label: Text('Create Your First Goal'),
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

  Widget _buildGoalsList() {
    // Sort goals: active first, then by deadline
    final sortedGoals = List<Goal>.from(_goals);
    sortedGoals.sort((a, b) {
      // First sort by completion status
      bool aCompleted = a.currentAmount >= a.targetAmount;
      bool bCompleted = b.currentAmount >= b.targetAmount;
      if (aCompleted != bCompleted) {
        return aCompleted ? 1 : -1;
      }

      // Then sort by deadline
      if (a.deadline != null && b.deadline != null) {
        return DateTime.parse(a.deadline!).compareTo(DateTime.parse(b.deadline!));
      } else if (a.deadline != null) {
        return -1;
      } else if (b.deadline != null) {
        return 1;
      }

      return 0;
    });

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedGoals.length,
      itemBuilder: (context, index) {
        return _buildGoalCard(sortedGoals[index]);
      },
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progressPercentage = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount)
        : 0.0;
    final isCompleted = progressPercentage >= 1.0;

    // Calculate days remaining if deadline exists
    String timeRemaining = '';
    if (goal.deadline != null) {
      final deadline = DateTime.parse(goal.deadline!);
      final now = DateTime.now();
      final difference = deadline.difference(now);

      if (difference.isNegative) {
        timeRemaining = 'Overdue';
      } else if (difference.inDays == 0) {
        timeRemaining = 'Due today';
      } else if (difference.inDays == 1) {
        timeRemaining = '1 day left';
      } else {
        timeRemaining = '${difference.inDays} days left';
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
          _showGoalDetails(goal);
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
                          goal.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1B263B), // Deep Navy Blue
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              goal.deadline != null
                                  ? timeRemaining
                                  : 'No deadline',
                              style: TextStyle(
                                color: goal.deadline != null &&
                                    DateTime.parse(goal.deadline!).isBefore(DateTime.now())
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Color(0xFF2ECC71).withOpacity(0.1) // Light Green
                          : Color(0xFFF4C542).withOpacity(0.1), // Light Gold
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.flag,
                        color: isCompleted
                            ? Color(0xFF2ECC71) // Emerald Green
                            : Color(0xFFF4C542), // Soft Gold
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
                        'Progress',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(progressPercentage * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCompleted
                              ? Color(0xFF2ECC71) // Emerald Green
                              : Color(0xFF1B263B), // Deep Navy Blue
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: currencyFormatter.format(goal.currentAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2ECC71), // Emerald Green
                              ),
                            ),
                            TextSpan(
                              text: ' / ${currencyFormatter.format(goal.targetAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1B263B), // Deep Navy Blue
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercentage > 1.0 ? 1.0 : progressPercentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? Color(0xFF2ECC71) // Emerald Green
                        : Color(0xFFF4C542), // Soft Gold
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalDetails(Goal goal) {
    final progressPercentage = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount)
        : 0.0;
    final isCompleted = progressPercentage >= 1.0;

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
                'Goal Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B263B), // Deep Navy Blue
                ),
              ),
              SizedBox(height: 16),
              _buildDetailRow('Name', goal.name),
              _buildDetailRow(
                'Target',
                currencyFormatter.format(goal.targetAmount),
                valueColor: Color(0xFF1B263B), // Deep Navy Blue
              ),
              _buildDetailRow(
                'Current Progress',
                currencyFormatter.format(goal.currentAmount),
                valueColor: Color(0xFF2ECC71), // Emerald Green
              ),
              _buildDetailRow(
                'Status',
                isCompleted ? 'Achieved! 🎉' : '${(progressPercentage * 100).toInt()}% Complete',
                valueColor: isCompleted ? Color(0xFF2ECC71) : Color(0xFFF4C542),
              ),
              if (goal.deadline != null)
                _buildDetailRow(
                  'Deadline',
                  DateFormat('MMMM dd, yyyy').format(DateTime.parse(goal.deadline!)),
                  valueColor: DateTime.parse(goal.deadline!).isBefore(DateTime.now()) && !isCompleted
                      ? Colors.red
                      : null,
                ),
              if (goal.createdAt != null)
                _buildDetailRow(
                  'Created',
                  DateFormat('MMMM dd, yyyy').format(DateTime.parse(goal.createdAt!)),
                ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _updateProgress(goal);
                    },
                    icon: Icon(Icons.update),
                    label: Text('Update Progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF4C542), // Soft Gold
                      foregroundColor: Color(0xFF1B263B), // Deep Navy Blue
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editGoal(goal);
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
                      _deleteGoal(goal);
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

  void _updateProgress(Goal goal) {
    final TextEditingController _progressController = TextEditingController();
    _progressController.text = goal.currentAmount.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current progress: ${currencyFormatter.format(goal.currentAmount)}',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _progressController,
                decoration: InputDecoration(
                  labelText: 'Current Amount',
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
                final amount = double.tryParse(_progressController.text);
                if (amount == null || amount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Update goal progress
                final updatedGoal = Goal(
                  id: goal.id,
                  name: goal.name,
                  targetAmount: goal.targetAmount,
                  currentAmount: amount,
                  deadline: goal.deadline,
                  createdAt: goal.createdAt,
                );

                try {
                  await _databaseService.updateGoal(updatedGoal);
                  _loadGoals();
                  Navigator.pop(context);

                  // Show congrats dialog if goal reached
                  if (amount >= goal.targetAmount && goal.currentAmount < goal.targetAmount) {
                    _showCongratulations(goal.name);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Progress updated successfully'),
                      backgroundColor: Color(0xFF2ECC71), // Emerald Green
                    ),
                  );
                } catch (e) {
                  print('Error updating goal progress: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update progress'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Update'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF2ECC71), // Emerald Green
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCongratulations(String goalName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Congratulations! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                color: Color(0xFFF4C542), // Soft Gold
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'You\'ve achieved your goal:',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                goalName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1B263B), // Deep Navy Blue
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Keep up the great work!',
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

  void _showAddGoalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return GoalForm(
          onGoalAdded: _loadGoals,
        );
      },
    );
  }

  void _editGoal(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return GoalForm(
          onGoalAdded: _loadGoals,
          goal: goal,
        );
      },
    );
  }

  void _deleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Goal'),
          content: Text('Are you sure you want to delete this goal?'),
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
                  await _databaseService.deleteGoal(goal.id!);
                  // Reload goals
                  _loadGoals();
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal deleted successfully'),
                      backgroundColor: Color(0xFF2ECC71), // Emerald Green
                    ),
                  );
                } catch (e) {
                  print('Error deleting goal: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete goal'),
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

class GoalForm extends StatefulWidget {
  final Function onGoalAdded;
  final Goal? goal;

  const GoalForm({
    Key? key,
    required this.onGoalAdded,
    this.goal,
  }) : super(key: key);

  @override
  _GoalFormState createState() => _GoalFormState();
}

class _GoalFormState extends State<GoalForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _targetAmountController = TextEditingController();
  TextEditingController _currentAmountController = TextEditingController();
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();

    // If editing an existing goal, populate the form
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _currentAmountController.text = widget.goal!.currentAmount.toString();
      if (widget.goal!.deadline != null) {
        _deadline = DateTime.parse(widget.goal!.deadline!);
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
              widget.goal == null ? 'Create New Goal' : 'Edit Goal',
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
                  // Goal Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Goal Name',
                      prefixIcon: Icon(Icons.flag),
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
                      hintText: 'e.g., New Car, Emergency Fund, Vacation',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for the goal';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Target Amount
                  TextFormField(
                    controller: _targetAmountController,
                    decoration: InputDecoration(
                      labelText: 'Target Amount',
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
                        return 'Please enter a target amount';
                      }
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Current Amount
                  TextFormField(
                    controller: _currentAmountController,
                    decoration: InputDecoration(
                      labelText: 'Current Progress',
                      prefixIcon: Icon(Icons.trending_up),
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
                      hintText: 'How much have you saved so far?',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter current progress';
                      }
                      if (double.tryParse(value) == null || double.parse(value) < 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Deadline Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _deadline ?? DateTime.now().add(Duration(days: 30)),
                        firstDate: DateTime.now(),
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
                          _deadline = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Deadline (Optional)',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: _deadline != null
                            ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _deadline = null;
                            });
                          },
                        )
                            : null,
                      ),
                      child: Text(
                        _deadline == null
                            ? 'No deadline set'
                            : DateFormat('MMMM dd, yyyy').format(_deadline!),
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
                          widget.goal == null ? 'Create Goal' : 'Update Goal',
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
        final goal = Goal(
          id: widget.goal?.id,
          name: _nameController.text,
          targetAmount: double.parse(_targetAmountController.text),
          currentAmount: double.parse(_currentAmountController.text),
          deadline: _deadline?.toIso8601String(),
        );

        if (widget.goal == null) {
          // Add new goal
          await _databaseService.insertGoal(goal);
        } else {
          // Update existing goal
          await _databaseService.updateGoal(goal);
        }

        // Notify parent that goal was added/updated
        widget.onGoalAdded();

        // Close the form
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.goal == null
                  ? 'Goal created successfully'
                  : 'Goal updated successfully',
            ),
            backgroundColor: Color(0xFF2ECC71), // Emerald Green
          ),
        );
      } catch (e) {
        print('Error saving goal: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save goal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}