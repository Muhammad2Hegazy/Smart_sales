# Smart Sales POS System

A comprehensive Point of Sale (POS) system built with Flutter for desktop (Windows, Linux, macOS), designed for restaurants, pharmacies, and supermarkets in Egypt.

## Features

### ✅ Completed

1. **Authentication System**
   - Login with username/password
   - Default admin user: `admin` / `mohamed2003`
   - Password hashing with SHA-256
   - User roles: Admin, Manager, Cashier

2. **Business Type Configuration**
   - Restaurant mode
   - Pharmacy mode
   - Supermarket mode
   - Admin-only settings screen
   - Runtime business type switching

3. **Localization**
   - Arabic and English support
   - RTL (Right-to-Left) support for Arabic
   - Runtime language switching
   - Comprehensive translation system

4. **Database Architecture**
   - SQLite database with sqflite_common_ffi for desktop
   - Complete schema for all modules
   - Clean Architecture pattern
   - Database initialization with default admin user

5. **User Interface**
   - Modern, clean design
   - Sidebar navigation
   - Permission-based screen visibility
   - Responsive layout

6. **Settings Management**
   - Company name configuration
   - Business type selection
   - Language selection
   - Sync mode configuration

### 🚧 In Progress / To Be Implemented

1. **User Management**
   - Create/Edit/Delete users
   - Permission assignment per screen
   - Role-based access control

2. **Sales (POS) Module**
   - Create sales invoices
   - Edit/Delete invoices
   - Returns handling
   - Discounts (item & invoice level)
   - Customer selection
   - Payment types (Cash, Credit, Partial)
   - Restaurant: Tables, Waiters, Kitchen tickets
   - Pharmacy: Batch numbers, Expiry dates
   - Supermarket: Barcode scanning, Weighted items

3. **Purchases Module**
   - Purchase invoices
   - Purchase returns
   - Supplier management
   - Supplier accounts

4. **Inventory Module**
   - Items & Categories management
   - Opening balance
   - Stock movements
   - Stock enforcement
   - Multi-price system (Retail, Wholesale, Offer)
   - Excel import/export

5. **Accounting Module**
   - Account management
   - Cash In/Out transactions
   - Journal entries
   - Account statements

6. **Reports Module**
   - Daily sales reports
   - Shift reports
   - Sales by item/category/customer/user
   - Inventory reports (stock balance, movements, expiry)
   - Accounting reports (statements, trial balance, P&L)

7. **Advanced Features**
   - Accounting day logic (changes at 5:00 AM)
   - Sync functionality (Standalone, Offline, Master/Client)
   - Audit logging
   - Database encryption
   - Excel templates per business type

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart      # App-wide constants
│   │   └── enums.dart              # Business enums
│   ├── utils/
│   │   ├── date_utils.dart         # Date utilities (accounting day logic)
│   │   └── localization.dart      # Localization system
│   └── theme/                      # App theming
├── domain/
│   └── entities/                   # Domain entities
│       ├── user.dart
│       ├── settings.dart
│       ├── item.dart
│       └── invoice.dart
├── data/
│   ├── database/
│   │   └── database_helper.dart    # SQLite database helper
│   ├── models/                     # Data models
│   │   └── user_model.dart
│   └── repositories/              # Data repositories
│       ├── user_repository.dart
│       └── settings_repository.dart
└── presentation/
    ├── providers/                  # State management (Riverpod)
    │   ├── auth_provider.dart
    │   └── settings_provider.dart
    └── screens/
        ├── auth/
        │   └── login_screen.dart
        ├── main/
        │   └── main_screen.dart
        ├── settings/
        │   └── settings_screen.dart
        ├── sales/
        │   └── pos_screen.dart
        ├── users/
        │   └── users_screen.dart
        ├── purchases/
        ├── inventory/
        ├── accounting/
        └── reports/
```

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- For Windows: Visual Studio with C++ build tools
- For Linux: Required development libraries
- For macOS: Xcode

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run -d windows  # For Windows
   flutter run -d linux    # For Linux
   flutter run -d macos    # For macOS
   ```

### Default Login

- **Username:** `admin`
- **Password:** `mohamed2003`

## Database Schema

The database includes the following main tables:

- `users` - User accounts and roles
- `permissions` - User permissions per screen
- `settings` - Application settings
- `categories` - Item categories
- `items` - Product/Item master data
- `item_batches` - Batch tracking (for Pharmacy)
- `stock_movements` - Inventory movements
- `customers` - Customer master
- `suppliers` - Supplier master
- `sales_invoices` - Sales transactions
- `sales_invoice_items` - Sales invoice line items
- `purchase_invoices` - Purchase transactions
- `purchase_invoice_items` - Purchase invoice line items
- `accounts` - Chart of accounts
- `journal_entries` - Accounting journal entries
- `journal_entry_lines` - Journal entry line items
- `cash_transactions` - Cash in/out transactions
- `audit_logs` - System audit trail
- `sync_queue` - Sync queue for multi-device sync

## Architecture

The project follows **Clean Architecture** principles:

- **Domain Layer**: Business entities and use cases
- **Data Layer**: Database, repositories, and data models
- **Presentation Layer**: UI screens, widgets, and state management

State management is handled using **Riverpod**.

## Business Logic

### Accounting Day

The accounting day changes at **5:00 AM**, not at midnight. All transactions after midnight but before 5 AM belong to the previous accounting day.

### Business Types

Each business type enables specific features:

- **Restaurant**: Tables, Waiters, Kitchen tickets, Split invoices
- **Pharmacy**: Batch numbers, Expiry dates, Expiry alerts
- **Supermarket**: Barcode scanning, Weighted items, Expiry tracking

## Development Status

This is an active development project. Core infrastructure is complete, and module implementation is ongoing.

## License

Proprietary - Hegazy Company

## Support

For issues and questions, please contact the development team.
# Smart_sales
