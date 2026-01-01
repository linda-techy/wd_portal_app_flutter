import 'package:flutter/material.dart';
import 'package:admin/services/labour_service.dart';
import 'package:admin/models/labour_models.dart';

class LabourProvider with ChangeNotifier {
  final LabourService _service = LabourService();

  List<Labour> _labourList = [];
  List<MeasurementBook> _mbEntries = [];
  bool _isLoading = false;
  String? _error;

  List<Labour> get labourList => _labourList;
  List<MeasurementBook> get mbEntries => _mbEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLabour() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getLabour();
      _labourList = (data as List).map((l) => Labour.fromJson(l)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createLabour(Labour labour) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.createLabour(labour.toJson());
      await fetchLabour();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordAttendance(List<LabourAttendance> attendanceList) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.recordAttendance(attendanceList.map((a) => a.toJson()).toList());
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMBEntries(int projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _service.getMBEntries(projectId);
      _mbEntries = (data as List).map((m) => MeasurementBook.fromJson(m)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMBEntry(MeasurementBook mb) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.createMBEntry(mb.toJson());
      await fetchMBEntries(mb.projectId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
