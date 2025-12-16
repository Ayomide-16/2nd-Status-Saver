/// Status Saver App - Entry Point
/// WhatsApp Status Saver with automatic caching and organization features.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/theme/theme_provider.dart';
import 'services/cache_service.dart';
import 'services/save_service.dart';
import 'services/status_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Storage service (handles permissions)
        ChangeNotifierProvider(create: (_) => StorageService()),
        
        // Status service (depends on storage service)
        ChangeNotifierProxyProvider<StorageService, StatusService>(
          create: (context) => StatusService(
            Provider.of<StorageService>(context, listen: false),
          ),
          update: (context, storageService, previous) {
            if (previous != null) {
              return previous;
            }
            return StatusService(storageService);
          },
        ),
        
        // Cache service
        ChangeNotifierProvider(create: (_) => CacheService()),
        
        // Save service
        ChangeNotifierProvider(create: (_) => SaveService()),
      ],
      child: const StatusSaverApp(),
    );
  }
}
