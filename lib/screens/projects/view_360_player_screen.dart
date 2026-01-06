import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';
import '../../models/view_360_models.dart';
import '../../constants.dart';
import '../../theme/app_theme.dart';

class View360PlayerScreen extends StatelessWidget {
  final View360 tour;

  const View360PlayerScreen({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(tour.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Panorama(
            child: Image.network(
              '${ApiConfig.baseUrl}${tour.panoramaUrl}',
              errorBuilder: (_, __, ___) => const Center(
                child: Text('Error loading panorama', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.vibration, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Drag to explore', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(defaultPadding * 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tour.title, style: AppTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Captured: ${tour.formattedCaptureDate}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (tour.location != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppTheme.coralRed),
                  const SizedBox(width: 8),
                  Text(tour.location!, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ],
            if (tour.description != null && tour.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(tour.description!, style: const TextStyle(color: AppTheme.textSecondary)),
            ],
            const SizedBox(height: 16),
            Text(
              'Uploaded by: ${tour.uploadedByName ?? 'System'}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
