import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:admin/services/gallery_service.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/utils/error_handler.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class GalleryScreen extends StatefulWidget {
  final int projectId;

  const GalleryScreen({super.key, required this.projectId});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final GalleryService _service = GalleryService();
  List<GalleryImage> _images = [];
  bool _isLoading = true;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _verifyAuthAndLoadData();
  }

  Future<void> _verifyAuthAndLoadData() async {
    final authProvider =
        Provider.of<PortalAuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      if (mounted) {
        await ErrorHandler.handleAuthError(context);
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final images = await _service.getProjectImages(widget.projectId);
      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await ErrorHandler.handleApiError(context, e,
            defaultMessage: 'Failed to load gallery');
      }
    }
  }

  Map<String, List<GalleryImage>> get _groupedByDate {
    final map = <String, List<GalleryImage>>{};
    final dateFormat = DateFormat('MMM d, yyyy');
    for (final img in _images) {
      final key = img.createdAt != null
          ? dateFormat.format(img.createdAt!)
          : 'Unknown Date';
      map.putIfAbsent(key, () => []).add(img);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery (${_images.length})'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No photos yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _isGridView ? _buildGridView() : _buildListView(),
                ),
    );
  }

  Widget _buildGridView() {
    final groups = _groupedByDate;
    return CustomScrollView(
      slivers: groups.entries.expand((entry) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.deepSlate.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${entry.value.length}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.deepSlate)),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGridTile(entry.value[index]),
                childCount: entry.value.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }

  Widget _buildGridTile(GalleryImage image) {
    return GestureDetector(
      onTap: () => _showImageDetail(image),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.grey[200],
              child: image.thumbnailPath != null || image.imagePath != null
                  ? Image.network(
                      image.thumbnailPath ?? image.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child:
                            Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.photo, color: Colors.grey)),
            ),
            if (image.locationTag != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.black54,
                  child: Text(
                    image.locationTag!,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _images.length,
      itemBuilder: (context, index) => _buildListTile(_images[index]),
    );
  }

  Widget _buildListTile(GalleryImage image) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showImageDetail(image),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: image.thumbnailPath != null || image.imagePath != null
                      ? Image.network(
                          image.thumbnailPath ?? image.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child:
                              const Icon(Icons.photo, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image.caption ?? 'Untitled',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (image.locationTag != null)
                      Text(
                        image.locationTag!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    if (image.createdAt != null)
                      Text(
                        dateFormat.format(image.createdAt!),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textTertiary),
                      ),
                  ],
                ),
              ),
              if (image.uploadedByName != null)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.deepSlate.withOpacity(0.1),
                  child: Text(
                    image.uploadedByName![0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.deepSlate),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDetail(GalleryImage image) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Image
            if (image.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image.imagePath!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 48, color: Colors.grey)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (image.caption != null && image.caption!.isNotEmpty)
              Text(image.caption!,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (image.locationTag != null)
              _buildInfoRow(Icons.location_on, 'Location', image.locationTag!),
            if (image.uploadedByName != null)
              _buildInfoRow(Icons.person, 'Uploaded by', image.uploadedByName!),
            if (image.createdAt != null)
              _buildInfoRow(Icons.calendar_today, 'Date',
                  dateFormat.format(image.createdAt!)),
            if (image.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: image.tags
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmDelete(image);
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete'),
              style:
                  OutlinedButton.styleFrom(foregroundColor: AppTheme.errorRed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(GalleryImage image) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _service.deleteImage(image.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Image deleted'),
                backgroundColor: AppTheme.successGreen),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          await ErrorHandler.handleApiError(context, e,
              defaultMessage: 'Failed to delete image');
        }
      }
    }
  }
}
