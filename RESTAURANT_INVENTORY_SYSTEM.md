# Restaurant Inventory, Recipe & Invoice Management System

## 📋 Overview

A comprehensive system for managing restaurant inventory, recipes, and invoices with automatic stock deduction and low stock alerts.

## 🔹 Core Rules

- **All weight-based raw materials use gram as base unit**
- **Input units allowed**: gram or kilogram
- **1 kilogram = 1000 grams** (auto conversion)
- **Sugar is stored and deducted by packet** (special case)

## 📦 Database Schema

### RawMaterials Table
```sql
CREATE TABLE raw_materials (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  base_unit TEXT NOT NULL DEFAULT 'gram',
  stock_quantity REAL NOT NULL DEFAULT 0,
  minimum_alert_quantity REAL NOT NULL DEFAULT 0,
  sub_category_id TEXT,
  unit TEXT NOT NULL DEFAULT 'number',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (sub_category_id) REFERENCES raw_material_sub_categories(id) ON DELETE SET NULL
)
```

### RawMaterialUnits Table
```sql
CREATE TABLE raw_material_units (
  id TEXT PRIMARY KEY,
  raw_material_id TEXT NOT NULL,
  unit TEXT NOT NULL,
  conversion_factor_to_base REAL NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE,
  UNIQUE(raw_material_id, unit)
)
```

### Recipes Table
```sql
CREATE TABLE recipes (
  id TEXT PRIMARY KEY,
  item_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
)
```

### RecipeIngredients Table
```sql
CREATE TABLE recipe_ingredients (
  id TEXT PRIMARY KEY,
  recipe_id TEXT NOT NULL,
  raw_material_id TEXT NOT NULL,
  quantity REAL NOT NULL,
  quantity_required_in_base_unit REAL NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
  FOREIGN KEY (raw_material_id) REFERENCES raw_materials(id) ON DELETE CASCADE
)
```

### Invoices Table
```sql
CREATE TABLE invoices (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  total_amount REAL NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

### InvoiceItems Table
```sql
CREATE TABLE invoice_items (
  id TEXT PRIMARY KEY,
  invoice_id TEXT NOT NULL,
  item_id TEXT NOT NULL,
  quantity_sold REAL NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE CASCADE
)
```

## ⚙️ Core Functions

### 1️⃣ addRawMaterialStock

Add raw material to stock with automatic unit conversion.

```dart
Future<void> addRawMaterialStock(
  String rawMaterialId,
  double quantity,
  String unit
) async
```

**Example:**
```dart
final dbHelper = DatabaseHelper();

// Add 5 kilograms of chicken (converts to 5000 grams)
await dbHelper.addRawMaterialStock(
  'chicken-id',
  5.0,
  'kilogram'
);

// Add 10 sugar packets
await dbHelper.addRawMaterialStock(
  'sugar-id',
  10.0,
  'packet'
);
```

### 2️⃣ convertToBaseUnit

Convert quantity from input unit to base unit.

```dart
Future<double> convertToBaseUnit(
  String rawMaterialId,
  double quantity,
  String unit
) async
```

**Example:**
```dart
// Convert 5 kg to grams (returns 5000.0)
final grams = await dbHelper.convertToBaseUnit(
  'chicken-id',
  5.0,
  'kilogram'
);
```

### 3️⃣ createInvoice

Create invoice and automatically deduct stock from recipes.

```dart
Future<Map<String, dynamic>> createInvoice({
  required DateTime date,
  required double totalAmount,
  required List<Map<String, dynamic>> invoiceItems,
}) async
```

**Returns:**
```dart
{
  'invoice_id': String,
  'warnings': List<String> // Low stock warnings
}
```

**Example:**
```dart
final result = await dbHelper.createInvoice(
  date: DateTime.now(),
  totalAmount: 150.0,
  invoiceItems: [
    {
      'item_id': 'sandwich-id',
      'quantity_sold': 3.0,
    },
    {
      'item_id': 'burger-id',
      'quantity_sold': 2.0,
    },
  ],
);

print('Invoice ID: ${result['invoice_id']}');
if (result['warnings'].isNotEmpty) {
  for (var warning in result['warnings']) {
    print(warning); // ⚠️ Raw material Chicken is running low...
  }
}
```

### 4️⃣ calculateAndDeductStock

Calculate required stock and deduct from inventory.

```dart
Future<List<String>> calculateAndDeductStock(
  List<Map<String, dynamic>> invoiceItems
) async
```

**Returns:** List of low stock warnings

**Example:**
```dart
final warnings = await dbHelper.calculateAndDeductStock([
  {
    'item_id': 'sandwich-id',
    'quantity_sold': 3.0,
  },
]);

if (warnings.isNotEmpty) {
  for (var warning in warnings) {
    print(warning);
  }
}
```

## 🧪 Example Usage

### Example 1: Add Stock

```dart
// Add 5 kilograms chicken → stores as 5000 grams
await dbHelper.addRawMaterialStock('chicken-id', 5.0, 'kilogram');

// Add 10 sugar packets
await dbHelper.addRawMaterialStock('sugar-id', 10.0, 'packet');
```

### Example 2: Define Recipe

```dart
// Recipe: 150 grams chicken per sandwich
final recipe = Recipe(
  id: 'recipe-id',
  itemId: 'sandwich-id',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  ingredients: [
    RecipeIngredient(
      id: 'ingredient-id',
      recipeId: 'recipe-id',
      rawMaterialId: 'chicken-id',
      quantityRequiredInBaseUnit: 150.0, // grams
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ],
);

await dbHelper.insertRecipe(recipe);
```

### Example 3: Create Invoice

```dart
// Sell 3 sandwiches using 150g chicken each → deducts 450 grams
final result = await dbHelper.createInvoice(
  date: DateTime.now(),
  totalAmount: 90.0,
  invoiceItems: [
    {
      'item_id': 'sandwich-id',
      'quantity_sold': 3.0,
    },
  ],
);

// Check warnings
if (result['warnings'].isNotEmpty) {
  print('Warnings:');
  for (var warning in result['warnings']) {
    print(warning);
  }
}
```

## 🚨 Validation Rules

1. **No negative stock allowed**: System validates stock before deduction
2. **Invalid units return errors**: Clear error messages for invalid conversions
3. **Stock validation**: Checks if sufficient stock exists before processing invoice
4. **Low stock alerts**: Automatically generates warnings when stock ≤ minimum_alert_quantity

## 📤 Error Messages

### Insufficient Stock
```
Exception: Insufficient stock for Chicken. 
Required: 450.0 gram, Available: 300.0 gram
```

### Invalid Unit
```
Exception: Invalid unit conversion: kilogram to bag
```

### Sugar Special Case
```
Exception: Sugar must use packet as unit
```

## 📤 Warning Messages

### Low Stock Alert
```
⚠️ Raw material Chicken is running low. 
Current: 100.0 gram, Minimum: 200.0 gram
```

## 🔧 Setup Instructions

1. **Database Migration**: System automatically migrates to version 22
2. **Create Raw Materials**: Use `insertRawMaterial` with `baseUnit` specified
3. **Set Minimum Alert**: Set `minimumAlertQuantity` for each raw material
4. **Define Recipes**: Create recipes with `quantityRequiredInBaseUnit` in base units
5. **Create Invoices**: Use `createInvoice` to automatically process stock deduction

## 📝 Notes

- All weight-based materials default to `gram` as base unit
- Sugar must use `packet` as base unit (no conversion)
- Recipes store quantities in base unit only
- Stock is validated before deduction
- Low stock warnings are returned after successful deduction

