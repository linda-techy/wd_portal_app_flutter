import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CctvCameraFormScreen extends StatefulWidget {
  final int projectId;
  final Map<String, dynamic>? cameraData; // null for create, populated for edit
  const CctvCameraFormScreen({super.key, required this.projectId, this.cameraData});

  @override
  State<CctvCameraFormScreen> createState() => _CctvCameraFormScreenState();
}

class _CctvCameraFormScreenState extends State<CctvCameraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _streamUrlCtrl;
  late TextEditingController _snapshotUrlCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _portCtrl;
  late TextEditingController _resolutionCtrl;

  String _provider = 'Generic IP';
  String _protocol = 'HLS';

  bool get isEdit => widget.cameraData != null;

  static const providers = ['Hikvision', 'Dahua', 'CP Plus', 'Generic IP'];
  static const protocols = ['HLS', 'RTSP', 'RTMP', 'HTTP'];

  @override
  void initState() {
    super.initState();
    final d = widget.cameraData;
    _nameCtrl = TextEditingController(text: d?['cameraName'] ?? '');
    _locationCtrl = TextEditingController(text: d?['location'] ?? '');
    _streamUrlCtrl = TextEditingController(text: d?['streamUrl'] ?? '');
    _snapshotUrlCtrl = TextEditingController(text: d?['snapshotUrl'] ?? '');
    _usernameCtrl = TextEditingController(text: d?['username'] ?? '');
    _passwordCtrl = TextEditingController(text: d?['password'] ?? '');
    _portCtrl = TextEditingController(text: d?['port']?.toString() ?? '');
    _resolutionCtrl = TextEditingController(text: d?['resolution'] ?? '');
    if (d != null) {
      _provider = d['provider'] ?? 'Generic IP';
      _protocol = d['streamProtocol'] ?? 'HLS';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'cameraName': _nameCtrl.text,
      'location': _locationCtrl.text,
      'provider': _provider,
      'streamProtocol': _protocol,
      'streamUrl': _streamUrlCtrl.text,
      'snapshotUrl': _snapshotUrlCtrl.text,
      'username': _usernameCtrl.text.isNotEmpty ? _usernameCtrl.text : null,
      'password': _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      'port': _portCtrl.text.isNotEmpty ? int.tryParse(_portCtrl.text) : null,
      'resolution': _resolutionCtrl.text.isNotEmpty ? _resolutionCtrl.text : null,
    };
    try {
      if (isEdit) {
        await _apiService.put('/api/cctv-cameras/${widget.cameraData!['id']}', data: body);
      } else {
        await _apiService.post('/api/projects/${widget.projectId}/cctv-cameras', data: body);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Camera' : 'Add Camera',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.deepSlate,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _save,
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Camera Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                hintText: 'e.g., Ground Floor Entrance',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: providers.contains(_provider) ? _provider : 'Generic IP',
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
              ),
              items: providers.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _provider = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: protocols.contains(_protocol) ? _protocol : 'HLS',
              decoration: const InputDecoration(
                labelText: 'Stream Protocol',
                border: OutlineInputBorder(),
              ),
              items: protocols.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _protocol = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streamUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Stream URL',
                border: OutlineInputBorder(),
                hintText: 'e.g., https://stream.example.com/live.m3u8',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _snapshotUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Snapshot URL',
                border: OutlineInputBorder(),
                hintText: 'Static image URL (fallback)',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Credentials (optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portCtrl,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _resolutionCtrl,
              decoration: const InputDecoration(
                labelText: 'Resolution',
                border: OutlineInputBorder(),
                hintText: 'e.g., 1080p',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
