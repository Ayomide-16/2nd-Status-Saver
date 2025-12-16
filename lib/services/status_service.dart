/// Status Saver App - Status Service
/// Scans and retrieves status files from WhatsApp directories.

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/status_file.dart';
import 'storage_service.dart';

class StatusService extends ChangeNotifier {
  final StorageService _storageService;
  
  List<StatusFile> _allStatuses = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastRefresh;
  
  List<StatusFile> get allStatuses => _allStatuses;
  List<StatusFile> get imageStatuses => 
      _allStatuses.where((s) => s.isImage).toList();
  List<StatusFile> get videoStatuses => 
      _allStatuses.where((s) => s.isVideo).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastRefresh => _lastRefresh;
  
  StatusService(this._storageService) {
    _storageService.addListener(_onStorageChange);
  }
  
  void _onStorageChange() {
    if (_storageService.hasPermission) {
      refreshStatuses();
    }
  }
  
  /// Refresh status list from storage
  Future<void> refreshStatuses() async {
    if (!_storageService.hasPermission) {
      _error = 'No storage permission';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (_storageService.usingSaf) {
        await _loadStatusesFromSaf();
      } else {
        await _loadStatusesFromLegacy();
      }
      _lastRefresh = DateTime.now();
    } catch (e) {
      _error = 'Error loading statuses: $e';
      debugPrint(_error);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  /// Load statuses using SAF (Android 11+)
  Future<void> _loadStatusesFromSaf() async {
    final filePaths = await _storageService.getFilesFromSaf();
    
    if (filePaths == null || filePaths.isEmpty) {
      // Try legacy access as fallback
      await _loadStatusesFromLegacy();
      return;
    }
    
    final statuses = <StatusFile>[];
    
    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      
      final name = path.split('/').last;
      final ext = name.contains('.') 
          ? name.substring(name.lastIndexOf('.')).toLowerCase() 
          : '';
      
      // Filter by supported extensions
      if (!MediaExtensions.all.contains(ext)) continue;
      
      try {
        final stat = await file.stat();
        statuses.add(StatusFile.fromSaf(
          path: path,
          name: name,
          modifiedTime: stat.modified,
          size: stat.size,
          statusType: StatusType.live,
        ));
      } catch (e) {
        debugPrint('Error reading file $path: $e');
      }
    }
    
    // Sort by modification time (newest first)
    statuses.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    _allStatuses = statuses;
  }
  
  /// Load statuses using legacy file access (Android 10 and below)
  Future<void> _loadStatusesFromLegacy() async {
    final statusPath = await _storageService.getStatusDirectoryPath();
    if (statusPath == null) {
      _allStatuses = [];
      return;
    }
    
    final statusDir = Directory(statusPath);
    if (!await statusDir.exists()) {
      _allStatuses = [];
      return;
    }
    
    final statuses = <StatusFile>[];
    
    await for (final entity in statusDir.list()) {
      if (entity is! File) continue;
      
      final name = entity.path.split(Platform.pathSeparator).last;
      
      // Skip .nomedia file
      if (name == '.nomedia') continue;
      
      final ext = name.contains('.') 
          ? name.substring(name.lastIndexOf('.')).toLowerCase() 
          : '';
      
      // Filter by supported extensions
      if (!MediaExtensions.all.contains(ext)) continue;
      
      try {
        statuses.add(StatusFile.fromFile(entity, StatusType.live));
      } catch (e) {
        debugPrint('Error reading file ${entity.path}: $e');
      }
    }
    
    // Sort by modification time (newest first)
    statuses.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    _allStatuses = statuses;
  }
  
  @override
  void dispose() {
    _storageService.removeListener(_onStorageChange);
    super.dispose();
  }
}
