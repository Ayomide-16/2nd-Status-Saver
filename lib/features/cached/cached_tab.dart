/// Status Saver App - Cached Tab
/// Displays cached statuses (auto-cached when viewed) with image/video sub-tabs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/status_file.dart';
import '../../services/cache_service.dart';
import '../media_viewer/media_viewer_screen.dart';
import '../status/widgets/status_grid.dart';

class CachedTab extends StatefulWidget {
  const CachedTab({super.key});

  @override
  State<CachedTab> createState() => _CachedTabState();
}

class _CachedTabState extends State<CachedTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load cached statuses on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CacheService>(context, listen: false).loadCachedStatuses();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cacheService = Provider.of<CacheService>(context);
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Cache info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto-cached statuses (expires after 7 days)',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text(
                cacheService.formattedCacheSize,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Sub-tabs for Images/Videos
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 18),
                  const SizedBox(width: 4),
                  Text('Images (${cacheService.cachedImages.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam, size: 18),
                  const SizedBox(width: 4),
                  Text('Videos (${cacheService.cachedVideos.length})'),
                ],
              ),
            ),
          ],
        ),
        
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Images tab
              StatusGrid(
                statuses: cacheService.cachedImages,
                isLoading: cacheService.isLoading,
                onRefresh: () => cacheService.loadCachedStatuses(),
                onTap: (status) => _onStatusTap(status, cacheService.cachedImages),
              ),
              
              // Videos tab
              StatusGrid(
                statuses: cacheService.cachedVideos,
                isLoading: cacheService.isLoading,
                onRefresh: () => cacheService.loadCachedStatuses(),
                onTap: (status) => _onStatusTap(status, cacheService.cachedVideos),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _onStatusTap(StatusFile status, List<StatusFile> allStatuses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewerScreen(
          statuses: allStatuses,
          initialIndex: allStatuses.indexOf(status),
        ),
      ),
    );
  }
}
