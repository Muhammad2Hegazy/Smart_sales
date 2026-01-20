import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'core/constants/app_constants.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/blocs/cart/cart_bloc.dart';
import 'presentation/blocs/navigation/navigation_bloc.dart';
import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/inventory/inventory_bloc.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/device/device_bloc.dart';
import 'presentation/blocs/device/device_event.dart';
import 'presentation/blocs/user_management/user_management_bloc.dart';
import 'core/database/database_helper.dart';
import 'core/services/product_service.dart';
import 'core/data_sources/local/master_local_data_source.dart';
import 'core/data_sources/local/device_local_data_source.dart';
import 'core/data_sources/local/auth_local_data_source.dart';
import 'core/data_sources/local/user_management_local_data_source.dart';
import 'core/repositories/device_repository.dart';
import 'core/repositories/user_management_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'data/repositories/product_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clear login state on app startup - users must log in each time
  try {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {
          throw TimeoutException('SharedPreferences timeout');
        },
      );
    } catch (e) {
      debugPrint('SharedPreferences timeout/error: $e');
      prefs = null;
    }

    if (prefs != null) {
      await prefs.setBool('auth_is_logged_in', false);
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_username');
      await prefs.remove('auth_user_role');
      debugPrint('Login state cleared on app startup');
    }
  } catch (e) {
    debugPrint('Error clearing login state: $e');
  }

  try {
    await DatabaseHelper.initialize().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('Database initialization timeout - continuing anyway');
      },
    );
  } catch (e) {
    debugPrint('Database initialization error: $e - continuing anyway');
  }

  // Initialize ProductService asynchronously - don't block app startup
  // ProductService will load data when first accessed
  Future.microtask(() async {
    try {
      final productService = ProductService();
      await productService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('ProductService initialization timeout - will load lazily');
        },
      );
    } catch (e) {
      debugPrint('ProductService initialization error: $e - will load lazily');
    }
  });

  // Start app immediately without waiting for anything
  runApp(const SmartSalesApp());
}


class SmartSalesApp extends StatefulWidget {
  const SmartSalesApp({super.key});

  @override
  State<SmartSalesApp> createState() => SmartSalesAppState();

  static SmartSalesAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<SmartSalesAppState>();
  }
}

class SmartSalesAppState extends State<SmartSalesApp> {
  Locale? _locale;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocale();

    // Fallback: if locale loading takes too long, use default
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isLoading) {
        debugPrint('Locale loading timeout - using default locale');
        setState(() {
          _locale = Locale(AppConstants.defaultLocale);
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadLocale() async {
    // Use default locale immediately to avoid blocking
    if (mounted) {
      setState(() {
        _locale = Locale(AppConstants.defaultLocale);
        _isLoading = false;
      });
    }

    // Try to load saved locale in background (non-blocking)
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {
            throw TimeoutException('SharedPreferences timeout');
          },
        );
        final languageCode = prefs.getString(AppConstants.keyLanguage) ??
            AppConstants.defaultLocale;
        if (mounted && _locale?.languageCode != languageCode) {
          setState(() {
            _locale = Locale(languageCode);
          });
        }
      } catch (e) {
        debugPrint('Error loading locale: $e - using default');
        // Already using default, no need to update
      }
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final dbHelper = DatabaseHelper();
    final authLocalDataSource = AuthLocalDataSource(dbHelper);
    final authRepository = AuthRepositoryImpl(authLocalDataSource);
    final productRepository = ProductRepositoryImpl(dbHelper);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IAuthRepository>.value(value: authRepository),
        RepositoryProvider<IProductRepository>.value(value: productRepository),
        RepositoryProvider<DatabaseHelper>.value(value: dbHelper),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CartBloc()),
          BlocProvider(create: (_) => NavigationBloc()),
          BlocProvider(create: (_) => ProductBloc()),
          BlocProvider(create: (_) => InventoryBloc()),
          // Auth BLoC (Using new Repository Implementation)
          BlocProvider(
            create: (context) => AuthBloc(context.read<IAuthRepository>()),
          ),
          BlocProvider(
            create: (context) {
              final dbHelper = context.read<DatabaseHelper>();
              final uuid = const Uuid();
              final masterLocalDataSource = MasterLocalDataSource(dbHelper);
              final deviceLocalDataSource = DeviceLocalDataSource(dbHelper);
              final deviceRepository = DeviceRepository(
                masterLocalDataSource,
                deviceLocalDataSource,
                uuid,
              );
              return DeviceBloc(deviceRepository);
            },
          ),
          // User Management BLoC (Local only)
          BlocProvider(
            create: (context) {
              final dbHelper = context.read<DatabaseHelper>();
              final userManagementLocalDataSource = UserManagementLocalDataSource();
              final userManagementRepository = UserManagementRepository(
                userManagementLocalDataSource,
                dbHelper,
              );

              return UserManagementBloc(userManagementRepository);
            },
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            // Only dispatch InitializeMaster once when authenticated
            if (authState is AuthAuthenticated) {
              context.read<DeviceBloc>().add(
                InitializeMaster(userId: authState.user.id),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is AuthAuthenticated) {
                return const MainScreen();
              } else if (authState is AuthUnauthenticated || authState is AuthInitial) {
                // Show login screen for unauthenticated or initial state
                return const LoginScreen();
              } else if (authState is AuthError) {
                // Show error or navigate to login
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Authentication Error: ${authState.message}'),
                        ElevatedButton(
                          onPressed: () => context.read<AuthBloc>().add(const AuthCheckRequested()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // Show loading screen while checking auth status (AuthLoading)
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
