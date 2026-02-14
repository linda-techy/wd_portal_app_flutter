import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:admin/services/api_service.dart';

/// A widget that loads images from authenticated API endpoints.
///
/// On Flutter Web, `Image.network(headers: ...)` is broken because browsers
/// render it as an HTML `<img>` tag which cannot send custom HTTP headers.
/// This widget uses Dio (which sends XHR requests with headers) to fetch
/// the image bytes, then displays them with `Image.memory`.
///
/// Auth is handled automatically via `ApiService().dio` which has an
/// `AuthInterceptor` that injects the Bearer token.
class AuthenticatedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AuthenticatedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<AuthenticatedImage> createState() => _AuthenticatedImageState();

  /// Clear the in-memory image cache (e.g. on logout).
  static void clearCache() => _AuthenticatedImageState._cache.clear();
}

class _AuthenticatedImageState extends State<AuthenticatedImage> {
  /// Simple in-memory cache so thumbnails in a grid don't re-fetch.
  static final Map<String, Uint8List> _cache = {};

  Uint8List? _bytes;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AuthenticatedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = widget.imageUrl;

    // Check cache first
    if (_cache.containsKey(url)) {
      if (mounted) {
        setState(() {
          _bytes = _cache[url];
          _loading = false;
          _hasError = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService().dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          // Override the default JSON accept header for image requests
          headers: {'Accept': '*/*'},
        ),
      );

      final bytes = Uint8List.fromList(response.data as List<int>);
      _cache[url] = bytes;

      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('AuthenticatedImage: Failed to load $url — $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_loading) {
      child = widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
    } else if (_hasError || _bytes == null) {
      child = widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, color: Colors.grey[400], size: 24),
          );
    } else {
      child = Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) =>
            widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[200],
              child:
                  Icon(Icons.broken_image, color: Colors.grey[400], size: 24),
            ),
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }
}
