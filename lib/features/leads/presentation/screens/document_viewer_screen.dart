import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Document viewer that supports both URL-based and byte-based rendering.
///
/// On web, [Image.network] and [SfPdfViewer.network] do not reliably send
/// custom auth headers, so callers should pre-fetch bytes with authentication
/// and pass them via [bytes]. The [url] / [headers] path is kept for
/// mobile/desktop where network widgets work correctly.
class DocumentViewerScreen extends StatelessWidget {
  final String? url;
  final String fileName;
  final String fileType; // 'pdf', 'image', etc.
  final Map<String, String>? headers;
  final Uint8List? bytes;

  const DocumentViewerScreen({
    super.key,
    this.url,
    required this.fileName,
    required this.fileType,
    this.headers,
    this.bytes,
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
    // Prefer bytes when available (always works, no header issues on web)
    if (bytes != null) {
      return _buildFromBytes(bytes!);
    }
    if (url != null) {
      return _buildFromUrl(url!);
    }
    return const Center(
      child: Text('No document data available.'),
    );
  }

  Widget _buildFromBytes(Uint8List data) {
    if (fileType == 'pdf') {
      return SfPdfViewer.memory(data);
    } else if (fileType == 'image') {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(
            data,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorWidget();
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

  Widget _buildFromUrl(String networkUrl) {
    if (fileType == 'pdf') {
      return SfPdfViewer.network(
        networkUrl,
        headers: headers,
      );
    } else if (fileType == 'image') {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            networkUrl,
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
              return _buildErrorWidget();
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

  Widget _buildErrorWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text('Failed to load document'),
        ],
      ),
    );
  }
}
