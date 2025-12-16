/// Status Saver App - Saved Tab
/// Displays saved statuses with image/video sub-tabs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/status_file.dart';
import '../../services/save_service.dart';
import '../media_viewer/media_viewer_screen.dart';
import '../status/widgets/status_grid.dart';

class SavedTab extends StatefulWidget {
  const SavedTab({super.key});

  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load saved statuses on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SaveService>(context, listen: false).loadSavedStatuses();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saveService = Provider.of<SaveService>(context);
    
    return Column(
      children: [
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
                  Text('Images (${saveService.savedImages.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam, size: 18),
                  const SizedBox(width: 4),
                  Text('Videos (${saveService.savedVideos.length})'),
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
                statuses: saveService.savedImages,
                isLoading: saveService.isLoading,
                onRefresh: () => saveService.loadSavedStatuses(),
                onTap: (status) => _onStatusTap(status, saveService.savedImages),
              ),
              
              // Videos tab
              StatusGrid(
                statuses: saveService.savedVideos,
                isLoading: saveService.isLoading,
                onRefresh: () => saveService.loadSavedStatuses(),
                onTap: (status) => _onStatusTap(status, saveService.savedVideos),
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
          showSaveButton: false, // Already saved
        ),
      ),
    );
  }
}
