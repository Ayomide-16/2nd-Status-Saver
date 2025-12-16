/// Status Saver App - Status Grid Widget
/// Displays a grid of status thumbnails.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_constants.dart';
import '../../models/status_file.dart';

class StatusGrid extends StatelessWidget {
  final List<StatusFile> statuses;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(StatusFile)? onTap;
  final Function(StatusFile)? onLongPress;
  final Set<StatusFile>? selectedStatuses;
  
  const StatusGrid({
    super.key,
    required this.statuses,
    this.isLoading = false,
    this.onRefresh,
    this.onTap,
    this.onLongPress,
    this.selectedStatuses,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && statuses.isEmpty) {
      return _buildLoadingGrid();
    }
    
    if (statuses.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      color: AppColors.whatsappGreen,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = selectedStatuses?.contains(status) ?? false;
          
          return StatusThumbnail(
            status: status,
            isSelected: isSelected,
            onTap: () => onTap?.call(status),
            onLongPress: () => onLongPress?.call(status),
          );
        },
      ),
    );
  }
  
  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: theme.iconTheme.color?.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            'No Statuses Found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (onRefresh != null)
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
        ],
      ),
    );
  }
}

class StatusThumbnail extends StatelessWidget {
  final StatusFile status;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  const StatusThumbnail({
    super.key,
    required this.status,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildThumbnail(),
          ),
          
          // Video indicator
          if (status.isVideo)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          
          // Selection overlay
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.whatsappGreen.withAlpha(77),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.whatsappGreen,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildThumbnail() {
    final file = File(status.path);
    
    if (status.isImage) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
        cacheWidth: 300,
        cacheHeight: 300,
      );
    } else {
      // For videos, show a placeholder with video icon
      // Video thumbnail can be generated using video_thumbnail package
      return Container(
        color: Colors.grey.shade800,
        child: const Center(
          child: Icon(
            Icons.videocam,
            color: Colors.white54,
            size: 40,
          ),
        ),
      );
    }
  }
}
