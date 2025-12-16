/// Status Saver App - Home Screen
/// Main screen with bottom navigation for Live, Saved, and Cached tabs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/storage_service.dart';
import '../cached/cached_tab.dart';
import '../permission/permission_screen.dart';
import '../saved/saved_tab.dart';
import '../settings/settings_screen.dart';
import '../status/status_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _tabs = const [
    StatusTab(),
    SavedTab(),
    CachedTab(),
  ];
  
  final List<String> _titles = const [
    'Live Status',
    'Saved',
    'Cached',
  ];

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    
    // Show permission screen if no access
    if (!storageService.hasPermission && !storageService.isLoading) {
      return const PermissionScreen();
    }
    
    // Show loading while checking permission
    if (storageService.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.whatsappGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Checking permissions...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.visibility_outlined),
            selectedIcon: Icon(Icons.visibility),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_outlined),
            selectedIcon: Icon(Icons.download),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.cached_outlined),
            selectedIcon: Icon(Icons.cached),
            label: 'Cached',
          ),
        ],
      ),
    );
  }
}
