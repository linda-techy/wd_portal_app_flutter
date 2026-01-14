import 'package:flutter/foundation.dart';
import 'package:admin/services/common_data_service.dart';
import 'package:admin/models/enum_value.dart';

class CommonDataProvider with ChangeNotifier {
  final CommonDataService _service = CommonDataService();

  // Cached data
  List<EnumValue> _projectPhases = [];
  List<EnumValue> _contractTypes = [];
  List<String> _states = [];
  Map<String, List<String>> _districtsByState = {};
  List<String> _projectTypes = [];
  List<String> _designPackages = [];
  List<String> _facingOptions = [];

  // Loading states
  bool _isPhasesLoading = false;
  bool _isContractTypesLoading = false;
  bool _isStatesLoading = false;
  bool _isProjectTypesLoading = false;
  bool _isDesignPackagesLoading = false;
  bool _isFacingOptionsLoading = false;

  // Data loaded flags
  bool _phasesLoaded = false;
  bool _contractTypesLoaded = false;
  bool _statesLoaded = false;
  bool _projectTypesLoaded = false;
  bool _designPackagesLoaded = false;
  bool _facingOptionsLoaded = false;

  String? _error;

  // Getters
  List<EnumValue> get projectPhases => _projectPhases;
  List<EnumValue> get contractTypes => _contractTypes;
  List<String> get states => _states;
  List<String> get projectTypes => _projectTypes;
  List<String> get designPackages => _designPackages;
  List<String> get facingOptions => _facingOptions;
  
  bool get isPhasesLoading => _isPhasesLoading;
  bool get isContractTypesLoading => _isContractTypesLoading;
  bool get isStatesLoading => _isStatesLoading;
  bool get isProjectTypesLoading => _isProjectTypesLoading;
  bool get isDesignPackagesLoading => _isDesignPackagesLoading;
  bool get isFacingOptionsLoading => _isFacingOptionsLoading;
  
  bool get isAnyLoading =>
      _isPhasesLoading ||
      _isContractTypesLoading ||
      _isStatesLoading ||
      _isProjectTypesLoading ||
      _isDesignPackagesLoading ||
      _isFacingOptionsLoading;
  
  String? get error => _error;

  /// Fetch project phases (cached)
  Future<List<EnumValue>> fetchProjectPhases({bool forceRefresh = false}) async {
    if (_phasesLoaded && !forceRefresh) {
      return _projectPhases;
    }

    _isPhasesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final phases = await _service.getProjectPhases();
      _projectPhases = phases;
      _phasesLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _projectPhases = [];
    } finally {
      _isPhasesLoading = false;
      notifyListeners();
    }

    return _projectPhases;
  }

  /// Fetch contract types (cached)
  Future<List<EnumValue>> fetchContractTypes({bool forceRefresh = false}) async {
    if (_contractTypesLoaded && !forceRefresh) {
      return _contractTypes;
    }

    _isContractTypesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final types = await _service.getContractTypes();
      _contractTypes = types;
      _contractTypesLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _contractTypes = [];
    } finally {
      _isContractTypesLoading = false;
      notifyListeners();
    }

    return _contractTypes;
  }

  /// Fetch states (cached)
  Future<List<String>> fetchStates({bool forceRefresh = false}) async {
    if (_statesLoaded && !forceRefresh) {
      return _states;
    }

    _isStatesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final states = await _service.getStates();
      _states = states;
      _statesLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _states = [];
    } finally {
      _isStatesLoading = false;
      notifyListeners();
    }

    return _states;
  }

  /// Fetch districts for a state (cached per state)
  Future<List<String>> fetchDistricts(String state, {bool forceRefresh = false}) async {
    if (_districtsByState.containsKey(state) && !forceRefresh) {
      return _districtsByState[state]!;
    }

    try {
      final districts = await _service.getDistricts(state);
      _districtsByState[state] = districts;
      notifyListeners();
      return districts;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get cached districts for a state
  List<String> getDistricts(String state) {
    return _districtsByState[state] ?? [];
  }

  /// Fetch project types (cached)
  Future<List<String>> fetchProjectTypes({bool forceRefresh = false}) async {
    if (_projectTypesLoaded && !forceRefresh) {
      return _projectTypes;
    }

    _isProjectTypesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final types = await _service.getProjectTypes();
      _projectTypes = types;
      _projectTypesLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _projectTypes = [];
    } finally {
      _isProjectTypesLoading = false;
      notifyListeners();
    }

    return _projectTypes;
  }

  /// Fetch design packages (cached)
  Future<List<String>> fetchDesignPackages({bool forceRefresh = false}) async {
    if (_designPackagesLoaded && !forceRefresh) {
      return _designPackages;
    }

    _isDesignPackagesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final packages = await _service.getDesignPackages();
      _designPackages = packages;
      _designPackagesLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _designPackages = [];
    } finally {
      _isDesignPackagesLoading = false;
      notifyListeners();
    }

    return _designPackages;
  }

  /// Fetch facing options (cached)
  Future<List<String>> fetchFacingOptions({bool forceRefresh = false}) async {
    if (_facingOptionsLoaded && !forceRefresh) {
      return _facingOptions;
    }

    _isFacingOptionsLoading = true;
    _error = null;
    notifyListeners();

    try {
      final options = await _service.getFacingOptions();
      _facingOptions = options;
      _facingOptionsLoaded = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _facingOptions = [];
    } finally {
      _isFacingOptionsLoading = false;
      notifyListeners();
    }

    return _facingOptions;
  }

  /// Load all common data at once
  Future<void> loadAll() async {
    await Future.wait([
      fetchProjectPhases(),
      fetchContractTypes(),
      fetchStates(),
      fetchProjectTypes(),
      fetchDesignPackages(),
      fetchFacingOptions(),
    ]);
  }

  /// Clear all cached data
  void clearCache() {
    _projectPhases = [];
    _contractTypes = [];
    _states = [];
    _districtsByState.clear();
    _projectTypes = [];
    _designPackages = [];
    _facingOptions = [];
    
    _phasesLoaded = false;
    _contractTypesLoaded = false;
    _statesLoaded = false;
    _projectTypesLoaded = false;
    _designPackagesLoaded = false;
    _facingOptionsLoaded = false;
    
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

