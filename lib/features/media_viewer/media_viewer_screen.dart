/// Status Saver App - Media Viewer Screen
/// Full-screen viewer for images and videos with save/share functionality.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/app_constants.dart';
import '../../models/status_file.dart';
import '../../services/cache_service.dart';
import '../../services/save_service.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<StatusFile> statuses;
  final int initialIndex;
  final bool showSaveButton;
  
  const MediaViewerScreen({
    super.key,
    required this.statuses,
    required this.initialIndex,
    this.showSaveButton = true,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeMedia();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
  
  void _initializeMedia() {
    final status = widget.statuses[_currentIndex];
    if (status.isVideo) {
      _initializeVideo(status);
    }
    
    // Auto-cache when viewing
    _cacheCurrentStatus();
  }
  
  void _initializeVideo(StatusFile status) async {
    _videoController?.dispose();
    _isVideoInitialized = false;
    
    _videoController = VideoPlayerController.file(File(status.path));
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.play();
    
    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }
  
  void _cacheCurrentStatus() {
    final cacheService = Provider.of<CacheService>(context, listen: false);
    final status = widget.statuses[_currentIndex];
    cacheService.cacheStatus(status);
  }
  
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    final status = widget.statuses[index];
    if (status.isVideo) {
      _initializeVideo(status);
    } else {
      _videoController?.pause();
    }
    
    _cacheCurrentStatus();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.statuses[_currentIndex];
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.statuses.length}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.showSaveButton)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () => _saveCurrentStatus(),
              tooltip: 'Save to gallery',
            ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareCurrentStatus(),
            tooltip: 'Share',
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.statuses.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final pageStatus = widget.statuses[index];
          
          if (pageStatus.isVideo) {
            return _buildVideoPlayer(pageStatus, index == _currentIndex);
          } else {
            return _buildImageViewer(pageStatus);
          }
        },
      ),
      bottomNavigationBar: _buildBottomInfo(status),
    );
  }
  
  Widget _buildImageViewer(StatusFile status) {
    return PhotoView(
      imageProvider: FileImage(File(status.path)),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.whatsappGreen,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text(
                'Failed to load image',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildVideoPlayer(StatusFile status, bool isCurrentPage) {
    if (!isCurrentPage) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam, color: Colors.white54, size: 64),
        ),
      );
    }
    
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.whatsappGreen,
        ),
      );
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          
          // Play/Pause overlay
          if (!_videoController!.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          
          // Progress bar
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.whatsappGreen,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomInfo(StatusFile status) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Row(
        children: [
          Icon(
            status.isVideo ? Icons.videocam : Icons.image,
            color: Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${status.formattedSize} • ${status.formattedTime}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _saveCurrentStatus() async {
    final saveService = Provider.of<SaveService>(context, listen: false);
    final status = widget.statuses[_currentIndex];
    
    final success = await saveService.saveStatus(status);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Saved to gallery' : 'Failed to save'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  void _shareCurrentStatus() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
      ),
    );
  }
}
