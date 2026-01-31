import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentViewerScreen extends StatelessWidget {
  final String url;
  final String fileName;
  final String fileType; // 'pdf', 'image', etc.
  final Map<String, String>? headers;

  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.fileName,
    required this.fileType,
    this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (fileType == 'pdf') {
      return SfPdfViewer.network(
        url,
        headers: headers,
      );
    } else if (fileType == 'image') {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            url,
            headers: headers,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text('Failed to load image'),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      return const Center(
        child: Text('Preview not available for this file type.'),
      );
    }
  }
}
