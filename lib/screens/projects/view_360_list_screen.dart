import 'package:flutter/material.dart';
import '../../models/view_360_models.dart';
import '../../services/view_360_service.dart';
import '../../theme/app_theme.dart';
import '../../constants.dart';
import './view_360_player_screen.dart';
import './upload_view_360_screen.dart';

class View360ListScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const View360ListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<View360ListScreen> createState() => _View360ListScreenState();
}

class _View360ListScreenState extends State<View360ListScreen> {
  final _service = View360Service();
  List<View360> _tours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    setState(() => _isLoading = true);
    try {
      final tours = await _service.getToursByProject(widget.projectId);
      setState(() {
        _tours = tours;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('${widget.projectName} - 360° Tours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTours,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadView360Screen(projectId: widget.projectId),
            ),
          );
          if (result == true) _fetchTours();
        },
        label: const Text('New Tour'),
        icon: const Icon(Icons.add_a_photo),
        backgroundColor: AppTheme.coralRed,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.coralRed))
          : _tours.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(defaultPadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _tours.length,
                  itemBuilder: (context, index) => _buildTourCard(_tours[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.vibration, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No 360° Tours found",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload your first 360 panorama view",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTourCard(View360 tour) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => View360PlayerScreen(tour: tour),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    '${ApiConfig.baseUrl}${tour.thumbnailUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                  const Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: Icon(Icons.panorama_fish_eye, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tour.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tour.formattedCaptureDate,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  if (tour.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 10, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            tour.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

