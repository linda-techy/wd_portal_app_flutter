import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:admin/models/site_report_models.dart';
import 'package:admin/theme/app_theme.dart';
import 'package:admin/constants.dart';

/// Detail screen for viewing a site report and its attached photos.
class SiteReportDetailScreen extends StatelessWidget {
  final SiteReport report;

  const SiteReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(report.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: defaultPadding),
            if (report.description != null &&
                report.description!.isNotEmpty) ...[
              _buildDescriptionCard(context),
              const SizedBox(height: defaultPadding),
            ],
            _buildPhotosSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.coralRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.reportType.label,
                    style: const TextStyle(
                      color: AppTheme.coralRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(report.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(
                      color: _statusColor(report.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today, 'Date', report.formattedDate),
            if (report.submittedByName != null)
              _infoRow(Icons.person, 'Submitted by', report.submittedByName!),
            if (report.latitude != null && report.longitude != null) ...[
              _infoRow(Icons.location_on, 'Location', 
                'Lat: ${report.latitude!.toStringAsFixed(5)}, Lng: ${report.longitude!.toStringAsFixed(5)}'),
              if (report.distanceFromProject != null)
                _infoRow(Icons.map, 'Distance from project', 
                  '${report.distanceFromProject!.toStringAsFixed(2)} km'),
            ],
            _infoRow(
                Icons.photo_library, 'Photos', '${report.photos.length}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text(
              report.description!,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (${report.photos.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (report.photos.isEmpty)
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No photos attached',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: report.photos.length,
            itemBuilder: (context, index) {
              return _PhotoTile(
                photo: report.photos[index],
                onTap: () => _showFullScreenPhoto(context, index),
              );
            },
          ),
      ],
    );
  }

  void _showFullScreenPhoto(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoViewer(
          photos: report.photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return Colors.blue;
      case 'REVIEWED':
        return AppTheme.successGreen;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// A single photo tile in the grid that loads images via authenticated request.
class _PhotoTile extends StatefulWidget {
  final SiteReportPhoto photo;
  final VoidCallback onTap;

  const _PhotoTile({required this.photo, required this.onTap});

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (mounted) setState(() => _token = token);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _token == null
            ? Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Image.network(
                widget.photo.fullUrl,
                headers: {'Authorization': 'Bearer $_token'},
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, error, __) => Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.grey),
                      const SizedBox(height: 4),
                      Text('Load failed',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Full screen photo viewer with swipe navigation.
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<SiteReportPhoto> photos;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  String? _token;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadToken();
  }

  Future<void> _loadToken() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (mounted) setState(() => _token = token);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          if (_token == null) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                photo.fullUrl,
                headers: {'Authorization': 'Bearer $_token'},
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    SizedBox(height: 8),
                    Text('Failed to load image',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
