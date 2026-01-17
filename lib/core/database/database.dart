// Database module barrel file
// 
// This file exports all database-related classes for easy importing.
// Usage: `import 'package:smart_sales/core/database/database.dart';`

// Core database components
export 'database_core.dart';
export 'base_dao.dart';
export 'migrations_helper.dart';

// Data Access Objects (DAOs)
export 'categories_dao.dart';
export 'items_dao.dart';
export 'sales_dao.dart';
export 'financial_dao.dart';
export 'users_dao.dart';
export 'devices_dao.dart';
export 'pending_invoices_dao.dart';
export 'raw_materials_dao.dart';
export 'recipes_dao.dart';
export 'inventory_dao.dart';
export 'suppliers_dao.dart';

// Legacy support - exports the main DatabaseHelper facade
export 'database_helper.dart';
