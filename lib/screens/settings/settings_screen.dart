import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:felixfund/services/auth_service.dart';
import 'package:felixfund/services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSecuritySection(),
          _buildDivider(),
          _buildBackupSection(),
          _buildDivider(),
          _buildAppearanceSection(),
          _buildDivider(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      'Security',
      Icons.security,
      [
        ListTile(
          leading: Icon(Icons.pin),
          title: Text('Change PIN'),
          trailing: Icon(Icons.chevron_right),
          onTap: _showChangePINDialog,
        ),
        ListTile(
          leading: Icon(Icons.fingerprint),
          title: Text('Enable Biometric Authentication'),
          trailing: Switch(
            value: false, // Get from preferences in a real app
            onChanged: (value) {
              // Enable biometric auth
              // Not implemented in this version
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBackupSection() {
    return _buildSection(
      'Backup & Data',
      Icons.backup,
      [
        ListTile(
          leading: Icon(Icons.cloud_upload),
          title: Text('Backup to Google Drive'),
          subtitle: Text('Last backup: Never'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            _backupService.backupDatabase(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.cloud_download),
          title: Text('Restore from Google Drive'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            _backupService.restoreDatabase(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.file_download),
          title: Text('Export to CSV'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            _backupService.exportToCSV(context);
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSection(
      'Appearance',
      Icons.palette,
      [
        ListTile(
          leading: Icon(Icons.brightness_6),
          title: Text('Dark Mode'),
          trailing: Switch(
            value: false, // Get from preferences in a real app
            onChanged: (value) {
              // Toggle theme
              // Not implemented in this version
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.attach_money),
          title: Text('Currency Format'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            // Show currency format options
            // Not implemented in this version
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      'About',
      Icons.info,
      [
        ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('App Version'),
          subtitle: Text('1.0.0'),
        ),
        ListTile(
          leading: Icon(Icons.code),
          title: Text('Developer'),
          subtitle: Text('Felix'),
        ),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Sign Out'),
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 32,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showChangePINDialog() {
    String currentPIN = '';
    String newPIN = '';
    String confirmPIN = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Current PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              onChanged: (value) {
                currentPIN = value;
              },
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              onChanged: (value) {
                newPIN = value;
              },
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              onChanged: (value) {
                confirmPIN = value;
              },
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
              if (newPIN.length != 4 || confirmPIN.length != 4) {
                _showErrorDialog('PIN must be 4 digits');
                return;
              }

              if (newPIN != confirmPIN) {
                _showErrorDialog('PINs do not match');
                return;
              }

              final authService = Provider.of<AuthService>(context, listen: false);
              final isValid = await authService.changePin(currentPIN, newPIN);

              Navigator.pop(context);

              if (isValid) {
                _showSuccessDialog('PIN changed successfully');
              } else {
                _showErrorDialog('Current PIN is incorrect');
              }
            },
            child: Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              final authService = Provider.of<AuthService>(context, listen: false);
              authService.logout();

              Navigator.pushReplacementNamed(context, '/pin');
            },
            child: Text('Sign Out'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}