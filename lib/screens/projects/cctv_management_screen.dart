import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'cctv_camera_form_screen.dart';

class CctvManagementScreen extends StatefulWidget {
  final int projectId;
  const CctvManagementScreen({super.key, required this.projectId});

  @override
  State<CctvManagementScreen> createState() => _CctvManagementScreenState();
}

class _CctvManagementScreenState extends State<CctvManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _cameras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiService.get('/api/projects/${widget.projectId}/cctv-cameras');
      setState(() {
        _cameras = resp.data is List ? resp.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCamera(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Camera'),
        content: const Text('Remove this camera configuration?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _apiService.delete('/api/cctv-cameras/$id');
      _loadCameras();
    }
  }

  Future<void> _toggleActive(int id) async {
    await _apiService.dio.patch('/api/cctv-cameras/$id/toggle');
    _loadCameras();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCTV Cameras', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.deepSlate,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.coralRed,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => CctvCameraFormScreen(projectId: widget.projectId),
          ));
          _loadCameras();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cameras.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('No cameras configured',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Tap + to add a CCTV camera',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCameras,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cameras.length,
                    itemBuilder: (context, index) {
                      final cam = _cameras[index];
                      final isActive = cam['isActive'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.videocam,
                            color: isActive ? AppTheme.tealAccent : Colors.grey,
                            size: 32,
                          ),
                          title: Text(
                            cam['cameraName'] ?? 'Camera',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${cam['location'] ?? ''} - ${cam['provider'] ?? ''}\n${cam['streamProtocol'] ?? ''} | ${cam['resolution'] ?? ''}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              switch (action) {
                                case 'edit':
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => CctvCameraFormScreen(
                                      projectId: widget.projectId,
                                      cameraData: cam,
                                    ),
                                  )).then((_) => _loadCameras());
                                  break;
                                case 'toggle':
                                  _toggleActive(cam['id']);
                                  break;
                                case 'delete':
                                  _deleteCamera(cam['id']);
                                  break;
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(isActive ? 'Disable' : 'Enable'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
