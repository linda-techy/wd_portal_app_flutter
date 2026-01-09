import 'package:admin/services/storage_service.dart';
import 'package:flutter/material.dart';

class MenuAppController extends ChangeNotifier {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StorageService _storage = StorageService();
  
  int _selectedIndex = 11; // Default to Tasks

  GlobalKey<ScaffoldState> get scaffoldKey => _scaffoldKey;
  int get selectedIndex => _selectedIndex;

  Future<void> initialize() async {
    final savedIndex = await _storage.read(key: 'selected_menu_index');
    if (savedIndex != null) {
      _selectedIndex = int.parse(savedIndex);
      notifyListeners();
    }
  }

  void setSelectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      _storage.write(key: 'selected_menu_index', value: index.toString());
      notifyListeners();
    }
  }

  void controlMenu() {
    if (!_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.openDrawer();
    }
  }
}
