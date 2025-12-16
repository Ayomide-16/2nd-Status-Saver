/// Status Saver App - Status Tab
/// Displays live statuses with image/video sub-tabs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/status_file.dart';
import '../../services/status_service.dart';
import '../../services/cache_service.dart';
import '../../services/save_service.dart';
import '../media_viewer/media_viewer_screen.dart';
import 'widgets/status_grid.dart';

class StatusTab extends StatefulWidget {
  const StatusTab({super.key});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<StatusFile> _selectedStatuses = {};
  bool _isSelectionMode = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load statuses on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatusService>(context, listen: false).refreshStatuses();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusService = Provider.of<StatusService>(context);
    
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
                  Text('Images (${statusService.imageStatuses.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam, size: 18),
                  const SizedBox(width: 4),
                  Text('Videos (${statusService.videoStatuses.length})'),
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
                statuses: statusService.imageStatuses,
                isLoading: statusService.isLoading,
                onRefresh: () => statusService.refreshStatuses(),
                onTap: (status) => _onStatusTap(status, statusService.imageStatuses),
                onLongPress: _onStatusLongPress,
                selectedStatuses: _selectedStatuses,
              ),
              
              // Videos tab
              StatusGrid(
                statuses: statusService.videoStatuses,
                isLoading: statusService.isLoading,
                onRefresh: () => statusService.refreshStatuses(),
                onTap: (status) => _onStatusTap(status, statusService.videoStatuses),
                onLongPress: _onStatusLongPress,
                selectedStatuses: _selectedStatuses,
              ),
            ],
          ),
        ),
        
        // Selection action bar
        if (_isSelectionMode)
          _buildSelectionBar(),
      ],
    );
  }
  
  void _onStatusTap(StatusFile status, List<StatusFile> allStatuses) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedStatuses.contains(status)) {
          _selectedStatuses.remove(status);
          if (_selectedStatuses.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedStatuses.add(status);
        }
      });
    } else {
      // Open media viewer and cache the status
      _cacheStatus(status);
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
  
  void _onStatusLongPress(StatusFile status) {
    setState(() {
      _isSelectionMode = true;
      _selectedStatuses.add(status);
    });
  }
  
  void _cacheStatus(StatusFile status) async {
    final cacheService = Provider.of<CacheService>(context, listen: false);
    await cacheService.cacheStatus(status);
  }
  
  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _cancelSelection,
            icon: const Icon(Icons.close),
          ),
          Text(
            '${_selectedStatuses.length} selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            onPressed: _saveSelectedStatuses,
            icon: const Icon(Icons.download),
            tooltip: 'Save selected',
          ),
        ],
      ),
    );
  }
  
  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedStatuses.clear();
    });
  }
  
  void _saveSelectedStatuses() async {
    final saveService = Provider.of<SaveService>(context, listen: false);
    final count = await saveService.saveMultipleStatuses(_selectedStatuses.toList());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $count statuses'),
          backgroundColor: Colors.green,
        ),
      );
      _cancelSelection();
    }
  }
}
