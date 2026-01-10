# Smart Sales - Architecture Documentation

## Folder Structure

### New Structure (OOP-Based)
```
lib/
├── core/
│   ├── constants/          # App constants and enums
│   ├── utils/             # Utility classes and helpers
│   └── base/              # Base classes for OOP patterns
├── domain/
│   └── entities/          # Domain models
├── data/
│   ├── database/          # Database helper
│   ├── models/            # Data models
│   └── repositories/     # Data access layer
└── presentation/
    ├── base/              # Base screen and provider classes
    ├── providers/        # Shared providers (auth, settings, permissions)
    ├── screens/
    │   ├── sales/
    │   │   ├── pos_screen.dart
    │   │   ├── providers/
    │   │   │   ├── sales_provider.dart
    │   │   │   └── pos_cart_provider.dart
    │   │   └── widgets/   # Sales-specific widgets
    │   ├── inventory/
    │   │   ├── inventory_screen.dart
    │   │   ├── providers/
    │   │   │   └── items_provider.dart
    │   │   └── widgets/   # Inventory-specific widgets
    │   ├── users/
    │   │   ├── users_screen.dart
    │   │   ├── providers/
    │   │   │   └── users_provider.dart
    │   │   └── widgets/   # User-specific widgets
    │   └── ...            # Other screens follow same pattern
    └── widgets/
        └── common/        # Shared reusable widgets
```

## OOP Principles Applied

### 1. Base Classes
- **`BaseScreen`**: Abstract base class for all screens
- **`BaseScreenState`**: Base state class with common functionality
- **`BaseState`**: Base state class for providers
- **`BaseNotifier`**: Base notifier with common methods

### 2. Helper Classes
- **`SettingsHelper`**: Utility for working with settings (DRY principle)
- Reusable components in `widgets/common/`

### 3. Separation of Concerns
- Each screen has its own folder with:
  - Screen file
  - `providers/` subfolder for screen-specific state management
  - `widgets/` subfolder for screen-specific widgets

### 4. Dependency Injection
- All repositories injected via providers
- Providers organized by feature/screen

## Benefits

1. **Maintainability**: Easy to find and modify code
2. **Scalability**: Easy to add new features
3. **Testability**: Clear separation makes testing easier
4. **Reusability**: Base classes and common widgets reduce duplication
5. **Organization**: Each feature is self-contained

## State Management

- **Riverpod 2.x** for state management
- **AsyncValue** for async operations
- **NotifierProvider** for synchronous state
- Providers organized by feature

## Code Quality

- Clean Architecture principles
- SOLID principles
- DRY (Don't Repeat Yourself)
- Consistent naming conventions
- Type safety throughout

