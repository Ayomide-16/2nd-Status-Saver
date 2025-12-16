/// Status Saver App - Settings Screen
/// Theme toggle and cache management.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/cache_service.dart';
import '../../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cacheService = Provider.of<CacheService>(context);
    final storageService = Provider.of<StorageService>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme section
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Theme'),
            subtitle: const Text('Switch between WhatsApp green and dark theme'),
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.setDarkMode(value),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.whatsappGreen,
            ),
          ),
          
          const Divider(),
          
          // Cache section
          _buildSectionHeader(context, 'Storage'),
          ListTile(
            leading: const Icon(Icons.cached, color: AppColors.whatsappGreen),
            title: const Text('Cache Size'),
            subtitle: Text('${cacheService.cachedStatuses.length} items • ${cacheService.formattedCacheSize}'),
            trailing: TextButton(
              onPressed: () => _clearCache(context),
              child: const Text('Clear'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder, color: AppColors.whatsappGreen),
            title: const Text('Storage Access'),
            subtitle: Text(
              storageService.hasPermission 
                  ? 'WhatsApp status folder accessible' 
                  : 'No access',
            ),
            trailing: storageService.hasPermission
                ? const Icon(Icons.check_circle, color: Colors.green)
                : TextButton(
                    onPressed: () => storageService.requestSafPermission(),
                    child: const Text('Grant'),
                  ),
          ),
          if (storageService.hasPermission)
            ListTile(
              leading: const Icon(Icons.link_off, color: Colors.orange),
              title: const Text('Reset Storage Access'),
              subtitle: const Text('Remove current folder access'),
              onTap: () => _resetStorageAccess(context),
            ),
          
          const Divider(),
          
          // About section
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.whatsappGreen),
            title: const Text('App Version'),
            subtitle: const Text(AppConfig.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.description, color: AppColors.whatsappGreen),
            title: const Text('About'),
            subtitle: const Text('Status Saver - Save WhatsApp statuses'),
            onTap: () => _showAboutDialog(context),
          ),
          
          const SizedBox(height: 32),
          
          // Cache info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_delete,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cached statuses are automatically deleted after 7 days',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.whatsappGreen,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will delete all cached statuses. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<CacheService>(context, listen: false).clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  void _resetStorageAccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Storage Access'),
        content: const Text(
          'This will remove the current folder access. You will need to grant permission again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<StorageService>(context, listen: false).clearPermission();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: AppConfig.appVersion,
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.whatsappGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.download,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'Save and manage WhatsApp statuses with automatic caching and organization.',
        ),
      ],
    );
  }
}
