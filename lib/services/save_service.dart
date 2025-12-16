/// Status Saver App - Save Service
/// Handles saving statuses to gallery and managing saved files.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../models/status_file.dart';

class SaveService extends ChangeNotifier {
  List<StatusFile> _savedStatuses = [];
  bool _isLoading = false;
  String? _error;
  
  List<StatusFile> get savedStatuses => _savedStatuses;
  List<StatusFile> get savedImages => 
      _savedStatuses.where((s) => s.isImage).toList();
  List<StatusFile> get savedVideos => 
      _savedStatuses.where((s) => s.isVideo).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  SaveService() {
    loadSavedStatuses();
  }
  
  /// Get saved directory path
  Future<Directory> get _savedDir async {
    // Use external storage for saved files so they show in gallery
    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      return Directory('${appDir.path}/${CacheConfig.savedFolderName}');
    }
    
    // Navigate up to get to shared storage
    final parts = externalDir.path.split('/');
    final baseIndex = parts.indexOf('Android');
    if (baseIndex > 0) {
      final basePath = parts.sublist(0, baseIndex).join('/');
      final savedDir = Directory('$basePath/Pictures/${CacheConfig.savedFolderName}');
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }
      return savedDir;
    }
    
    return Directory('${externalDir.path}/${CacheConfig.savedFolderName}');
  }
  
  /// Load saved statuses from saved directory
  Future<void> loadSavedStatuses() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final savedDir = await _savedDir;
      final statuses = <StatusFile>[];
      
      if (await savedDir.exists()) {
        await for (final entity in savedDir.list()) {
          if (entity is File) {
            final name = entity.path.split(Platform.pathSeparator).last;
            final ext = name.contains('.') 
                ? name.substring(name.lastIndexOf('.')).toLowerCase() 
                : '';
            
            if (!MediaExtensions.all.contains(ext)) continue;
            
            try {
              final status = StatusFile.fromFile(entity, StatusType.saved);
              statuses.add(status);
            } catch (e) {
              debugPrint('Error reading saved file: $e');
            }
          }
        }
      }
      
      // Sort by modification time (newest first)
      statuses.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
      _savedStatuses = statuses;
    } catch (e) {
      _error = 'Error loading saved statuses: $e';
      debugPrint(_error);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Save a status to gallery using gal package
  Future<bool> saveStatus(StatusFile status) async {
    try {
      final sourceFile = File(status.path);
      
      if (!await sourceFile.exists()) {
        _error = 'Source file does not exist';
        return false;
      }
      
      // Use gal package to save to gallery
      if (status.isVideo) {
        await Gal.putVideo(status.path, album: CacheConfig.savedFolderName);
      } else {
        await Gal.putImage(status.path, album: CacheConfig.savedFolderName);
      }
      
      debugPrint('Saved status to gallery: ${status.name}');
      await loadSavedStatuses();
      return true;
    } on GalException catch (e) {
      _error = 'Gallery error: ${e.type.name}';
      debugPrint(_error);
      return false;
    } catch (e) {
      _error = 'Error saving status: $e';
      debugPrint(_error);
      return false;
    }
  }
  
  /// Save multiple statuses to gallery
  Future<int> saveMultipleStatuses(List<StatusFile> statuses) async {
    int successCount = 0;
    
    for (final status in statuses) {
      final success = await saveStatus(status);
      if (success) successCount++;
    }
    
    await loadSavedStatuses();
    return successCount;
  }
  
  /// Check if a status is already saved
  Future<bool> isSaved(StatusFile status) async {
    final savedDir = await _savedDir;
    final savedFile = File('${savedDir.path}/${status.name}');
    return savedFile.exists();
  }
  
  /// Delete a saved status
  Future<bool> deleteSavedStatus(StatusFile status) async {
    try {
      final file = File(status.path);
      if (await file.exists()) {
        await file.delete();
      }
      
      await loadSavedStatuses();
      return true;
    } catch (e) {
      _error = 'Error deleting saved status: $e';
      debugPrint(_error);
      return false;
    }
  }
}
