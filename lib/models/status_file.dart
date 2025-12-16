/// Status Saver App - Status File Model
/// Represents a WhatsApp status file (image or video).

import 'dart:io';

enum StatusType {
  live,   // Current status from WhatsApp
  saved,  // Saved to gallery by user
  cached, // Auto-cached when viewed
}

enum MediaType {
  image,
  video,
}

class StatusFile {
  final String path;
  final String name;
  final DateTime modifiedTime;
  final MediaType mediaType;
  final StatusType statusType;
  final int size;
  
  StatusFile({
    required this.path,
    required this.name,
    required this.modifiedTime,
    required this.mediaType,
    required this.statusType,
    required this.size,
  });
  
  /// Check if this is a video file
  bool get isVideo => mediaType == MediaType.video;
  
  /// Check if this is an image file
  bool get isImage => mediaType == MediaType.image;
  
  /// Get file extension
  String get extension => name.contains('.') 
      ? name.substring(name.lastIndexOf('.')).toLowerCase() 
      : '';
  
  /// Get file object
  File get file => File(path);
  
  /// Create StatusFile from a File
  factory StatusFile.fromFile(File file, StatusType type) {
    final stat = file.statSync();
    final name = file.path.split(Platform.pathSeparator).last;
    final ext = name.contains('.') 
        ? name.substring(name.lastIndexOf('.')).toLowerCase() 
        : '';
    
    final isVideo = ['.mp4', '.3gp', '.mkv', '.avi', '.webm'].contains(ext);
    
    return StatusFile(
      path: file.path,
      name: name,
      modifiedTime: stat.modified,
      mediaType: isVideo ? MediaType.video : MediaType.image,
      statusType: type,
      size: stat.size,
    );
  }
  
  /// Create StatusFile from SAF document info
  factory StatusFile.fromSaf({
    required String path,
    required String name,
    required DateTime modifiedTime,
    required int size,
    required StatusType statusType,
  }) {
    final ext = name.contains('.') 
        ? name.substring(name.lastIndexOf('.')).toLowerCase() 
        : '';
    
    final isVideo = ['.mp4', '.3gp', '.mkv', '.avi', '.webm'].contains(ext);
    
    return StatusFile(
      path: path,
      name: name,
      modifiedTime: modifiedTime,
      mediaType: isVideo ? MediaType.video : MediaType.image,
      statusType: statusType,
      size: size,
    );
  }
  
  /// Format file size for display
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Format modified time for display
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(modifiedTime);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${modifiedTime.day}/${modifiedTime.month}/${modifiedTime.year}';
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusFile &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
  
  @override
  String toString() => 'StatusFile(name: $name, type: $mediaType, status: $statusType)';
}
