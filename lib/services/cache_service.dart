/// Status Saver App - Cache Service
/// Manages automatic caching of viewed statuses with 7-day expiration.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/status_file.dart';

class CacheService extends ChangeNotifier {
  List<StatusFile> _cachedStatuses = [];
  bool _isLoading = false;
  String? _error;
  int _cacheSize = 0;
  
  List<StatusFile> get cachedStatuses => _cachedStatuses;
  List<StatusFile> get cachedImages => 
      _cachedStatuses.where((s) => s.isImage).toList();
  List<StatusFile> get cachedVideos => 
      _cachedStatuses.where((s) => s.isVideo).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get formattedCacheSize {
    if (_cacheSize < 1024) return '$_cacheSize B';
    if (_cacheSize < 1024 * 1024) return '${(_cacheSize / 1024).toStringAsFixed(1)} KB';
    return '${(_cacheSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  CacheService() {
    _init();
  }
  
  Future<void> _init() async {
    await _cleanExpiredCache();
    await loadCachedStatuses();
  }
  
  /// Get cache directory path
  Future<Directory> get _cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/status_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }
  
  /// Get cache timestamps from SharedPreferences
  Future<Map<String, int>> _getCacheTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(CacheConfig.cachePrefsKey);
    if (json == null) return {};
    
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }
  
  /// Save cache timestamps to SharedPreferences
  Future<void> _saveCacheTimestamps(Map<String, int> timestamps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheConfig.cachePrefsKey, jsonEncode(timestamps));
  }
  
  /// Clean expired cache files (older than 7 days)
  Future<void> _cleanExpiredCache() async {
    try {
      final cacheDir = await _cacheDir;
      final timestamps = await _getCacheTimestamps();
      final now = DateTime.now().millisecondsSinceEpoch;
      final expirationMs = CacheConfig.maxCacheDays * 24 * 60 * 60 * 1000;
      
      final expiredKeys = <String>[];
      
      for (final entry in timestamps.entries) {
        if (now - entry.value > expirationMs) {
          expiredKeys.add(entry.key);
          
          // Delete the file
          final file = File('${cacheDir.path}/${entry.key}');
          if (await file.exists()) {
            await file.delete();
            debugPrint('Deleted expired cache: ${entry.key}');
          }
        }
      }
      
      // Update timestamps
      for (final key in expiredKeys) {
        timestamps.remove(key);
      }
      await _saveCacheTimestamps(timestamps);
    } catch (e) {
      debugPrint('Error cleaning expired cache: $e');
    }
  }
  
  /// Load cached statuses from cache directory
  Future<void> loadCachedStatuses() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final cacheDir = await _cacheDir;
      final statuses = <StatusFile>[];
      int totalSize = 0;
      
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            final name = entity.path.split(Platform.pathSeparator).last;
            final ext = name.contains('.') 
                ? name.substring(name.lastIndexOf('.')).toLowerCase() 
                : '';
            
            if (!MediaExtensions.all.contains(ext)) continue;
            
            try {
              final status = StatusFile.fromFile(entity, StatusType.cached);
              statuses.add(status);
              totalSize += status.size;
            } catch (e) {
              debugPrint('Error reading cached file: $e');
            }
          }
        }
      }
      
      // Sort by modification time (newest first)
      statuses.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
      _cachedStatuses = statuses;
      _cacheSize = totalSize;
    } catch (e) {
      _error = 'Error loading cached statuses: $e';
      debugPrint(_error);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Cache a status file (called when viewing a status)
  Future<bool> cacheStatus(StatusFile status) async {
    try {
      final cacheDir = await _cacheDir;
      final sourceFile = File(status.path);
      
      if (!await sourceFile.exists()) {
        debugPrint('Source file does not exist: ${status.path}');
        return false;
      }
      
      // Generate unique filename to avoid conflicts
      final cachedPath = '${cacheDir.path}/${status.name}';
      final cachedFile = File(cachedPath);
      
      // Skip if already cached
      if (await cachedFile.exists()) {
        debugPrint('Already cached: ${status.name}');
        return true;
      }
      
      // Copy file to cache
      await sourceFile.copy(cachedPath);
      
      // Save timestamp
      final timestamps = await _getCacheTimestamps();
      timestamps[status.name] = DateTime.now().millisecondsSinceEpoch;
      await _saveCacheTimestamps(timestamps);
      
      debugPrint('Cached status: ${status.name}');
      
      // Reload cached statuses
      await loadCachedStatuses();
      
      return true;
    } catch (e) {
      debugPrint('Error caching status: $e');
      return false;
    }
  }
  
  /// Check if a status is already cached
  Future<bool> isCached(StatusFile status) async {
    final cacheDir = await _cacheDir;
    final cachedFile = File('${cacheDir.path}/${status.name}');
    return cachedFile.exists();
  }
  
  /// Delete a cached status
  Future<bool> deleteCachedStatus(StatusFile status) async {
    try {
      final file = File(status.path);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from timestamps
      final timestamps = await _getCacheTimestamps();
      timestamps.remove(status.name);
      await _saveCacheTimestamps(timestamps);
      
      // Reload cached statuses
      await loadCachedStatuses();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting cached status: $e');
      return false;
    }
  }
  
  /// Clear all cached statuses
  Future<void> clearCache() async {
    try {
      final cacheDir = await _cacheDir;
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      
      // Clear timestamps
      await _saveCacheTimestamps({});
      
      _cachedStatuses = [];
      _cacheSize = 0;
      notifyListeners();
    } catch (e) {
      _error = 'Error clearing cache: $e';
      debugPrint(_error);
    }
  }
}
