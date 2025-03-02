import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:felixfund/services/auth_service.dart';
import 'package:felixfund/screens/dashboard/dashboard_screen.dart';

class PinScreen extends StatefulWidget {
  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _pin = '';
  bool _isError = false;
  String _errorMessage = '';

  void _addDigit(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _isError = false;
      });

      // Check if PIN is complete (4 digits)
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  void _verifyPin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isValid = await authService.verifyPin(_pin);

    if (isValid) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen())
      );
    } else {
      setState(() {
        _isError = true;
        _errorMessage = 'Incorrect PIN. Please try again.';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
        decoration: BoxDecoration(
        image: DecorationImage(
        image: AssetImage('assets/images/app_background.png'),
    fit: BoxFit.cover,
    ),
    ),
    child: SafeArea(
    child: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
              Text(
                'Enter PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),

              // PIN dots display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),

              // Error message
              if (_isError) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 40),

              // PIN keypad
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  children: [
                    // Digits 1-9
                    for (int i = 1; i <= 9; i++)
                      _buildDigitButton(i.toString()),

                    // Empty space (or you could add a fingerprint button here)
                    Container(),

                    // Digit 0
                    _buildDigitButton('0'),

                    // Delete button
                    IconButton(
                      icon: Icon(Icons.backspace_outlined),
                      onPressed: _removeDigit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
        ),
    );
  }

  Widget _buildDigitButton(String digit) {
    return InkWell(
      onTap: () => _addDigit(digit),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

class SetupPinScreen extends StatefulWidget {
  @override
  _SetupPinScreenState createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isError = false;
  String _errorMessage = '';

  void _addDigit(String digit) {
    if (!_isConfirming && _pin.length < 4) {
      setState(() {
        _pin += digit;
        _isError = false;
      });

      // Move to confirm PIN after 4 digits
      if (_pin.length == 4) {
        setState(() {
          _isConfirming = true;
        });
      }
    } else if (_isConfirming && _confirmPin.length < 4) {
      setState(() {
        _confirmPin += digit;
        _isError = false;
      });

      // Check if confirmation PIN is complete
      if (_confirmPin.length == 4) {
        _verifyAndSavePin();
      }
    }
  }

  void _removeDigit() {
    if (_isConfirming && _confirmPin.isNotEmpty) {
      setState(() {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        _isError = false;
      });
    } else if (!_isConfirming && _pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  void _verifyAndSavePin() async {
    if (_pin == _confirmPin) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.createPin(_pin);

      if (success) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DashboardScreen())
        );
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to save PIN. Please try again.';
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
      }
    } else {
      setState(() {
        _isError = true;
        _errorMessage = 'PINs do not match. Please try again.';
        _confirmPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isConfirming ? 'Confirm PIN' : 'Create PIN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                _isConfirming
                    ? 'Please enter the PIN again to confirm'
                    : 'Create a 4-digit PIN to secure your data',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // PIN dots display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isConfirming
                          ? (index < _confirmPin.length
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300)
                          : (index < _pin.length
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300),
                    ),
                  ),
                ),
              ),

              // Error message
              if (_isError) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 40),

              // PIN keypad
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  children: [
                    // Digits 1-9
                    for (int i = 1; i <= 9; i++)
                      _buildDigitButton(i.toString()),

                    // Empty space
                    Container(),

                    // Digit 0
                    _buildDigitButton('0'),

                    // Delete button
                    IconButton(
                      icon: Icon(Icons.backspace_outlined),
                      onPressed: _removeDigit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitButton(String digit) {
    return InkWell(
      onTap: () => _addDigit(digit),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}