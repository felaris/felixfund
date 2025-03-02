import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:felixfund/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  Future<String> _getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return path.join(dbPath, 'felixfund.db');
  }

  Future<void> backupDatabase(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        Navigator.pop(context);
        throw Exception('Google Sign-In cancelled');
      }

      // Get authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        Navigator.pop(context);
        throw Exception('Failed to get access token');
      }

      // Get the database file
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      // Check if database file exists
      if (!await dbFile.exists()) {
        Navigator.pop(context);
        throw Exception('Database file not found');
      }

      // Read database file
      final List<int> databaseBytes = await dbFile.readAsBytes();

      // Create authenticated HTTP client
      final authClient = _AuthClient(accessToken);

      // Create Drive API client
      final driveApi = drive.DriveApi(authClient);

      // Create backup folder if it doesn't exist
      String folderId = await _getBackupFolderId(driveApi);

      // Format date for backup filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'felixfund_backup_$timestamp.db';

      // Create Drive file metadata
      final driveFile = drive.File()
        ..name = backupFileName
        ..parents = [folderId]
        ..mimeType = 'application/octet-stream';

      // Upload file to Drive
      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(
          Stream.value(databaseBytes),
          databaseBytes.length,
        ),
      );

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Backup Successful'),
          content: Text('Your database has been backed up to Google Drive.'),
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
    } catch (e) {
      print('Error backing up database: $e');

      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Backup Failed'),
          content: Text('Failed to backup database: ${e.toString()}'),
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
  }

  Future<void> restoreDatabase(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        Navigator.pop(context);
        throw Exception('Google Sign-In cancelled');
      }

      // Get authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        Navigator.pop(context);
        throw Exception('Failed to get access token');
      }

      // Create authenticated HTTP client
      final authClient = _AuthClient(accessToken);

      // Create Drive API client
      final driveApi = drive.DriveApi(authClient);

      // Get backup folder ID
      String folderId = await _getBackupFolderId(driveApi);

      // List all backup files in the folder
      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and name contains 'felixfund_backup' and trashed = false",
        orderBy: 'modifiedTime desc',
      );

      // Close loading dialog
      Navigator.pop(context);

      if (fileList.files == null || fileList.files!.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No Backups Found'),
            content: Text('No database backups were found in Google Drive.'),
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
        return;
      }

      // Show backup selection dialog
      final selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Backup to Restore'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fileList.files!.length,
              itemBuilder: (context, index) {
                final file = fileList.files![index];
                final fileName = file.name ?? 'Unknown';
                final modifiedTime = file.modifiedTime != null
                    ? DateFormat('yyyy-MM-dd HH:mm').format(file.modifiedTime!)
                    : 'Unknown date';

                return ListTile(
                  title: Text(fileName),
                  subtitle: Text('Modified: $modifiedTime'),
                  onTap: () {
                    Navigator.pop(context, file);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedFile == null) {
        return;
      }

      // Confirm restore
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Restore'),
          content: Text(
              'This will replace your current database with the selected backup. '
                  'All current data will be lost. Continue?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Restore'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      );

      if (shouldRestore != true) {
        return;
      }

      // Show loading dialog again
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Download the selected backup file
      final media = await driveApi.files.get(
        selectedFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (final data in media.stream) {
        dataStore.addAll(data);
      }

      // Get database path
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);

      // Close database connection before restoring
      await DatabaseService().closeDatabase();

      // Write downloaded data to database file
      await dbFile.writeAsBytes(dataStore, flush: true);

      // Reinitialize database
      await DatabaseService().initDatabase();

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Restore Successful'),
          content: Text(
              'Your database has been restored successfully. '
                  'The app will now restart to apply the changes.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Restart app (You would typically use a package like flutter_phoenix here)
                // For now, we'll just return to the login screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/pin',
                      (route) => false,
                );
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error restoring database: $e');

      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Restore Failed'),
          content: Text('Failed to restore database: ${e.toString()}'),
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
  }

  Future<String> _getBackupFolderId(drive.DriveApi driveApi) async {
    // Check if backup folder exists
    final folderList = await driveApi.files.list(
      q: "name = 'FelixFund Backups' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
    );

    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id!;
    }

    // Create backup folder if it doesn't exist
    final folder = drive.File()
      ..name = 'FelixFund Backups'
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folder);
    return createdFolder.id!;
  }

  Future<void> exportToCSV(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final DatabaseService dbService = DatabaseService();

      // Get data for export
      final accounts = await dbService.getAccounts();
      final transactions = await dbService.getTransactions();

      // Create temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      // Export accounts
      final accountsFile = File('${tempDir.path}/felixfund_accounts_$timestamp.csv');
      final accountsCSV = StringBuffer();

      // Write header
      accountsCSV.writeln('id,name,balance,type,details,created_at');

      // Write data
      for (final account in accounts) {
        accountsCSV.writeln(
            '${account.id},${_escapeCSV(account.name)},${account.balance},${_escapeCSV(account.type)},${_escapeCSV(account.details ?? "")},${account.createdAt}'
        );
      }

      await accountsFile.writeAsString(accountsCSV.toString());

      // Export transactions
      final transactionsFile = File('${tempDir.path}/felixfund_transactions_$timestamp.csv');
      final transactionsCSV = StringBuffer();

      // Write header
      transactionsCSV.writeln('id,amount,type,category,description,account_id,date,is_want,source');

      // Write data
      for (final transaction in transactions) {
        transactionsCSV.writeln(
            '${transaction.id},${transaction.amount},${transaction.type},${_escapeCSV(transaction.category)},${_escapeCSV(transaction.description ?? "")},${transaction.accountId},${transaction.date},${transaction.isWant ? 1 : 0},${_escapeCSV(transaction.source ?? "")}'
        );
      }

      await transactionsFile.writeAsString(transactionsCSV.toString());

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Export Successful'),
          content: Text(
              'Your data has been exported to CSV files:\n\n'
                  '${accountsFile.path}\n\n'
                  '${transactionsFile.path}\n\n'
                  'You can now share these files using the share button below.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
            // Note: In a real app, you would add share functionality here using a package like share_plus
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Share files
                // share_plus package would be used here
              },
              child: Text('Share Files'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error exporting to CSV: $e');

      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Export Failed'),
          content: Text('Failed to export data: ${e.toString()}'),
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
  }

  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

// Custom HTTP client for Google Drive authentication
class _AuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  _AuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}