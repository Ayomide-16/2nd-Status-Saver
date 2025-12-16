/// Status Saver App - Storage Service
/// Handles SAF permission requests and storage access using platform channels.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class StorageService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.statussaver.status_saver/saf');
  
  bool _hasPermission = false;
  String? _safUri;
  bool _isLoading = false;
  String? _error;
  
  bool get hasPermission => _hasPermission;
  String? get safUri => _safUri;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  StorageService() {
    _checkExistingPermission();
  }
  
  /// Check if we already have permission (from previous session)
  Future<void> _checkExistingPermission() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _safUri = prefs.getString(AppConfig.safUriPrefsKey);
      
      // Check basic storage permission for legacy access
      final status = await Permission.storage.status;
      if (status.isGranted) {
        _hasPermission = await _checkLegacyAccess();
      }
      
      // If SAF URI is stored, we should have permission
      if (_safUri != null && _safUri!.isNotEmpty) {
        _hasPermission = true;
      }
    } catch (e) {
      _error = 'Error checking permissions: $e';
      debugPrint(_error);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Check if legacy file access works (Android 10 and below)
  Future<bool> _checkLegacyAccess() async {
    try {
      // Check primary storage
      final externalDir = Directory('/storage/emulated/0');
      if (!await externalDir.exists()) return false;
      
      // Try to find WhatsApp status directory
      for (final path in StatusPaths.allPaths) {
        final statusDir = Directory('${externalDir.path}/$path');
        if (await statusDir.exists()) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Legacy access check failed: $e');
      return false;
    }
  }
  
  /// Request storage permission (legacy for Android < 11)
  Future<bool> requestStoragePermission() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      
      if (status.isGranted) {
        _hasPermission = await _checkLegacyAccess();
        if (!_hasPermission) {
          _error = 'WhatsApp status folder not found. Please make sure WhatsApp is installed.';
        }
      } else if (status.isPermanentlyDenied) {
        _error = 'Permission permanently denied. Please enable in Settings.';
        openAppSettings();
      } else {
        _error = 'Storage permission denied';
      }
    } catch (e) {
      _error = 'Error requesting permission: $e';
    }
    
    _isLoading = false;
    notifyListeners();
    return _hasPermission;
  }
  
  /// Request SAF permission (Android 11+)
  Future<bool> requestSafPermission() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Try to open SAF directory picker via platform channel
      final result = await _channel.invokeMethod<String>('openDocumentTree');
      
      if (result != null && result.isNotEmpty) {
        _safUri = result;
        _hasPermission = true;
        
        // Save for future sessions
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.safUriPrefsKey, result);
      } else {
        // Fall back to storage permission request
        _error = 'SAF not available. Trying legacy access...';
        await requestStoragePermission();
      }
    } on PlatformException catch (e) {
      debugPrint('SAF Platform error: ${e.message}');
      // Fall back to legacy permission
      _error = 'Using legacy storage access...';
      await requestStoragePermission();
    } catch (e) {
      // Fall back to legacy permission
      debugPrint('SAF error: $e');
      await requestStoragePermission();
    }
    
    _isLoading = false;
    notifyListeners();
    return _hasPermission;
  }
  
  /// Get the status directory path (for legacy access)
  Future<String?> getStatusDirectoryPath() async {
    if (_safUri != null && _safUri!.isNotEmpty) {
      return _safUri;
    }
    
    final externalDir = Directory('/storage/emulated/0');
    if (!await externalDir.exists()) return null;
    
    for (final path in StatusPaths.allPaths) {
      final statusDir = Directory('${externalDir.path}/$path');
      if (await statusDir.exists()) {
        return statusDir.path;
      }
    }
    
    return null;
  }
  
  /// Get list of files from SAF directory
  Future<List<String>?> getFilesFromSaf() async {
    if (_safUri == null || _safUri!.isEmpty) return null;
    
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('listFiles', {
        'uri': _safUri,
      });
      return result?.cast<String>();
    } catch (e) {
      debugPrint('Error listing SAF files: $e');
      return null;
    }
  }
  
  /// Check if we're using SAF or legacy access
  bool get usingSaf => _safUri != null && _safUri!.isNotEmpty;
  
  /// Clear permission and require re-grant
  Future<void> clearPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.safUriPrefsKey);
    _safUri = null;
    _hasPermission = false;
    notifyListeners();
  }
}
