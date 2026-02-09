import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:motion_toast/motion_toast.dart';
import '../../services/view_360_service.dart';
import '../../theme/app_theme.dart';
import '../../constants.dart';
import '../../utils/file_upload_helper.dart';

class UploadView360Screen extends StatefulWidget {
  final int projectId;

  const UploadView360Screen({super.key, required this.projectId});

  @override
  State<UploadView360Screen> createState() => _UploadView360ScreenState();
}

class _UploadView360ScreenState extends State<UploadView360Screen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _service = View360Service();

  FileUploadData? _selectedFileData;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFileData = FileUploadHelper.extractFromResult(result);
        });
      }
    } catch (e) {
      MotionToast.error(description: Text('Error picking image: $e'))
          .show(context);
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFileData == null) {
      MotionToast.warning(
              description: const Text('Please select a 360 panorama image'))
          .show(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.uploadTour(
        projectId: widget.projectId,
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        file: _selectedFileData!.file,
        bytes: _selectedFileData!.bytes,
        fileName: _selectedFileData!.fileName,
      );

      MotionToast.success(
              description: const Text('Virtual tour uploaded successfully'))
          .show(context);
      Navigator.pop(context, true);
    } catch (e) {
      MotionToast.error(description: Text('Error uploading tour: $e'))
          .show(context);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Upload 360° Panorama'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.coralRed),
              ),
            )
          else
            TextButton(
              onPressed: _handleUpload,
              child: const Text('UPLOAD',
                  style: TextStyle(
                      color: AppTheme.coralRed, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: defaultPadding * 2),
              _buildTextField(
                  'Title', _titleController, 'e.g., Living Room View'),
              const SizedBox(height: defaultPadding),
              _buildTextField(
                  'Location/Room', _locationController, 'e.g., First Floor'),
              const SizedBox(height: defaultPadding),
              _buildTextField('Description (Optional)', _descriptionController,
                  'Add some details...',
                  maxLines: 3),
              const SizedBox(height: defaultPadding * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Panorama Image',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey.shade300, style: BorderStyle.solid),
            ),
            child: _selectedFileData != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Display image - use file if available, otherwise show placeholder
                        _selectedFileData!.file != null
                            ? Image.file(_selectedFileData!.file!,
                                fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image,
                                      size: 48, color: Colors.grey),
                                ),
                              ),
                        Container(color: Colors.black26),
                        const Center(
                            child: Icon(Icons.panorama,
                                color: Colors.white, size: 48)),
                      ],
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to select panorama from gallery',
                          style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('(Should be a 2:1 equirectangular image)',
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (val) => label.contains('Optional')
              ? null
              : (val == null || val.isEmpty ? '$label is required' : null),
        ),
      ],
    );
  }
}
