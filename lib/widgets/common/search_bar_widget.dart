import 'package:flutter/material.dart';
import 'dart:async';

/// Reusable search bar widget with debouncing
/// Used across all modules for consistent search UX
class SearchBarWidget extends StatefulWidget {
  final String? initialValue;
  final Function(String) onSearch;
  final Function()? onClear;
  final String hintText;
  final Duration debounce;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;

  const SearchBarWidget({
    super.key,
    this.initialValue,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search...',
    this.debounce = const Duration(milliseconds: 500),
    this.enabled = true,
    this.prefix,
    this.suffix,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounce?.cancel();

    // Start new timer
    _debounce = Timer(widget.debounce, () {
      widget.onSearch(value.trim());
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onSearch('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefix ?? const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
                tooltip: 'Clear search',
              )
            : widget.suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
