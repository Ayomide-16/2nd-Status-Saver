/// Status Saver App - Constants
/// Defines app-wide constants including colors, paths, and configuration values.

import 'package:flutter/material.dart';

/// WhatsApp theme colors
class AppColors {
  // WhatsApp Green Theme
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappDarkGreen = Color(0xFF128C7E);
  static const Color whatsappTeal = Color(0xFF075E54);
  static const Color whatsappLightGreen = Color(0xFFDCF8C6);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF0F2F5);
  static const Color lightText = Color(0xFF000000);
  static const Color lightSecondaryText = Color(0xFF667781);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF121B22);
  static const Color darkSurface = Color(0xFF1F2C34);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFF8696A0);
}

/// WhatsApp status directory paths
class StatusPaths {
  // Standard WhatsApp paths
  static const String whatsappStatusPath = 'Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
  static const String whatsappLegacyPath = 'WhatsApp/Media/.Statuses';
  
  // WhatsApp Business paths
  static const String whatsappBusinessPath = 'Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses';
  static const String whatsappBusinessLegacyPath = 'WhatsApp Business/Media/.Statuses';
  
  // All possible status paths
  static List<String> get allPaths => [
    whatsappStatusPath,
    whatsappLegacyPath,
    whatsappBusinessPath,
    whatsappBusinessLegacyPath,
  ];
}

/// Supported media extensions
class MediaExtensions {
  static const List<String> images = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  static const List<String> videos = ['.mp4', '.3gp', '.mkv', '.avi', '.webm'];
  static List<String> get all => [...images, ...videos];
}

/// Cache configuration
class CacheConfig {
  static const int maxCacheDays = 7;
  static const String cachePrefsKey = 'status_cache_timestamps';
  static const String savedFolderName = 'Status Saver';
}

/// App configuration
class AppConfig {
  static const String appName = 'Status Saver';
  static const String appVersion = '1.0.0';
  static const String themePrefsKey = 'app_theme_dark';
  static const String safUriPrefsKey = 'saf_directory_uri';
}
