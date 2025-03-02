# FelixFund - Personal Budget App

FelixFund is a comprehensive personal budget tracking app built with Flutter for Android. This app helps you manage your finances by tracking your income, expenses, savings, debts, and financial goals.

## Table of Contents
- [Features](#features)
- [Setup and Installation](#setup-and-installation)
- [App Structure](#app-structure)
- [Core Functionality](#core-functionality)
- [Data Security](#data-security)
- [Backup and Restore](#backup-and-restore)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)

## Features

- **Financial Overview**: Track total money, account balances, and debts in a single dashboard
- **Expense Management**: Log daily spending with detailed categorization
- **Income Tracking**: Record income sources and amounts
- **Savings Tracking**: Monitor multiple savings accounts
- **Debt Management**: Track outstanding debts and record payments
- **Goal Setting**: Set financial goals and track progress
- **Budget Insights**: Set monthly limits for different categories
- **Secure Storage**: PIN protection and encrypted sensitive data
- **Google Drive Backup**: Manual backup and restore capabilities

## Setup and Installation

### Prerequisites
- Flutter SDK (2.5.0 or higher)
- Android Studio or VS Code
- Android SDK (API level 19 or higher)
- A physical Android device or emulator

### Installation Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/felixfund.git
   cd felixfund
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Configuring Google Drive Backup

To enable the Google Drive backup feature:

1. Create a project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the Google Drive API
3. Configure OAuth consent screen:
   - Set user type (external or internal)
   - Add scope: `https://www.googleapis.com/auth/drive.file`
4. Create OAuth 2.0 client ID:
   - For Android app, you'll need SHA-1 certificate fingerprint
   - For iOS, you'll need your bundle ID
5. Update Android configuration:
   - Add your web client ID to `android/app/src/main/res/values/strings.xml`:
     ```xml
     <resources>
         <string name="app_name">FelixFund</string>
         <string name="server_client_id">YOUR_WEB_CLIENT_ID</string>
     </resources>
     ```

## App Structure

FelixFund is organized with a clean architecture and follows the separation of concerns principle:

```
lib/
├── config/           # App configuration
│   ├── app_theme.dart
│   └── routes.dart
├── models/           # Data models
│   ├── account.dart
│   ├── transaction.dart
│   ├── saving.dart
│   ├── budget.dart
│   ├── goal.dart
│   └── debt.dart
├── screens/          # UI screens
│   ├── auth/
│   ├── dashboard/
│   ├── accounts/
│   ├── transactions/
│   ├── budget/
│   ├── savings/
│   ├── goals/
│   ├── debts/
│   └── settings/
├── services/         # Business logic
│   ├── database_service.dart
│   ├── auth_service.dart
│   └── backup_service.dart
├── widgets/          # Reusable components
└── main.dart         # App entry point
```

## Core Functionality

### Authentication Flow
- App starts with a splash screen displaying the FelixFund logo
- On first run, user creates a 4-digit PIN
- Subsequent launches require PIN entry
- PIN is securely stored using Flutter Secure Storage

### Data Management
- **Local Database**: SQLite (via sqflite package)
- **State Management**: Provider pattern
- **Transactions**: CRUD operations for all financial data

### Dashboard
- Shows total balance, income, expenses, savings, and debt
- Displays recent transactions
- Charts for spending categories
- Quick access to other features

### Financial Tracking Logic
- **Accounts**: Bank accounts with name, type, balance
- **Transactions**: Income or expense entries with category, amount, date
- **Budget**: Monthly spending limits by category
- **Savings**: Track savings accounts and goals
- **Debts**: Track debts with interest rates and due dates
- **Goals**: Financial goals with targets and progress tracking

## Data Security

FelixFund takes security seriously:

- **PIN Protection**: 4-digit PIN required at app startup
- **Sensitive Data**: Account credentials stored using Flutter Secure Storage
- **Local Storage**: All data stays on your device by default
- **Encrypted Backup**: Database backups to Google Drive are secured by your Google account

## Backup and Restore

The app provides manual backup and restore functionality:

### Backup Process
1. Go to Settings > Backup to Google Drive
2. Authenticate with your Google account when prompted
3. The app creates a "FelixFund Backups" folder in Google Drive
4. A timestamped copy of your database is uploaded
5. Previous backups are preserved for safety

### Restore Process
1. Go to Settings > Restore from Google Drive
2. Authenticate with Google if necessary
3. Select from available backups (sorted by date)
4. Confirm replacement of current data
5. App will restart with the restored data

### Data Export
- Export data to CSV files via Settings > Export to CSV
- Exported files can be shared via the system share dialog

## Customization

You can customize the app appearance and behavior:

### Color Scheme
The app uses these primary colors which can be modified in `app_theme.dart`:
- Primary: Emerald Green (#2ECC71)
- Secondary: Deep Navy Blue (#1B263B)
- Accent: Soft Gold (#F4C542)

### Asset Images
You'll need to prepare and add these images:
- `app_logo.png`: App icon and branding
- `app_background.png`: Optional background for login screen
- `empty_savings.png`: Placeholder for empty savings screen
- `empty_goals.png`: Placeholder for empty goals screen
- `empty_debt.png`: Placeholder for empty debt screen

## Troubleshooting

### Common Issues and Solutions

1. **Database Errors**
   - Issue: "No such table" errors
   - Solution: Check database initialization in `database_service.dart`

2. **Backup Failures**
   - Issue: Can't connect to Google Drive
   - Solution: Verify Google Cloud Console setup and credentials

3. **Build Errors**
   - Issue: Conflicts between model classes
   - Solution: Ensure `Transaction` is renamed to `TransactionModel` to avoid conflict with sqflite

4. **Performance Issues**
   - Issue: Slow loading with many transactions
   - Solution: Implement pagination in list views

For any other issues, check the logs for detailed error messages and stack traces.

---

FelixFund is designed as a personal budget app with a focus on ease of use and comprehensive financial tracking. Feel free to customize and extend it to suit your specific financial management needs!