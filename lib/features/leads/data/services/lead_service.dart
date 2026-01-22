// Extract Lead Service
import 'dart:typed_data';
import 'dart:io';
import 'package:dio/dio.dart'; // Import Dio for MultipartFile
import 'package:admin/features/leads/data/models/lead.dart';
import 'package:admin/models/paginated_response.dart';
import 'package:admin/models/pagination_params.dart';
import 'package:admin/models/team_member_simple.dart';
import 'package:admin/services/api_service.dart';
import 'package:admin/features/leads/data/models/activity_feed.dart';
import 'package:admin/features/leads/data/models/lead_document.dart';
import 'package:admin/features/leads/data/models/lead_interaction.dart';
import 'package:admin/features/leads/data/models/lead_score_history.dart';

class LeadService {
  final ApiService _apiService = ApiService();

  Future<List<TeamMemberSimple>> getTeamMembersForAssignment() async {
    final response = await _apiService.get('/users/team-members');
    return _apiService.unwrapList<TeamMemberSimple>(
        response, (json) => TeamMemberSimple.fromJson(json));
  }

  Future<List<Lead>> getAllLeads() async {
    final response = await _apiService.get('/leads');
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  Future<PaginatedResponse<Lead>> getLeadsPaginated(
      PaginationParams params) async {
    final queryParams = params.toQueryParams();
    final response =
        await _apiService.get('/leads/paginated', queryParams: queryParams);
    return _apiService.unwrap<PaginatedResponse<Lead>>(
        response,
        (json) => PaginatedResponse.fromJson(
            json as Map<String, dynamic>, Lead.fromJson));
  }

  /// NEW: Standardized search endpoint with 0-based pagination
  Future<PaginatedResponse<Lead>> searchLeads({
    required int page, // 0-based
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          if (value is DateTime) {
            queryParams[key] = value.toIso8601String().split('T')[0];
          } else {
            queryParams[key] = value.toString();
          }
        }
      });
    }

    final response =
        await _apiService.get('/leads/search', queryParams: queryParams);
    // Backend returns ApiResponse<Page<Lead>>, unwrap extracts the Page object
    // which is then converted to PaginatedResponse
    return _apiService.unwrap<PaginatedResponse<Lead>>(
      response,
      (json) {
        // Handle both direct Page format and wrapped in ApiResponse
        Map<String, dynamic> pageData;
        if (json is Map<String, dynamic> && json.containsKey('data')) {
          // If wrapped in ApiResponse, extract data field
          pageData = json['data'] as Map<String, dynamic>;
        } else {
          pageData = json as Map<String, dynamic>;
        }
        return PaginatedResponse.fromJson(pageData, Lead.fromJson);
      },
    );
  }

  Future<Lead> getLeadById(String id) async {
    final response = await _apiService.get('/leads/$id');
    return _apiService.unwrap<Lead>(
        response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<Lead> createLead(Lead lead) async {
    final response =
        await _apiService.post('/leads', data: lead.toCreateJson());
    return _apiService.unwrap<Lead>(
        response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<Lead> updateLead(String id, Lead lead) async {
    final response =
        await _apiService.put('/leads/$id', data: lead.toUpdateJson());
    return _apiService.unwrap<Lead>(
        response, (json) => Lead.fromJson(json as Map<String, dynamic>));
  }

  Future<void> deleteLead(String id) async {
    final response = await _apiService.delete('/leads/$id');
    _apiService.unwrap<void>(response, (_) {});
  }

  // Filtering & Stats methods...
  Future<List<Lead>> getLeadsByStatus(String status) async {
    final response = await _apiService.get('/leads/status/$status');
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  Future<List<Lead>> getLeadsByAssignedTo(String teamMemberId) async {
    final response = await _apiService.get('/leads/assigned/$teamMemberId');
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  // OLD: Deprecated - use searchLeads() with pagination instead
  @Deprecated('Use searchLeads() with pagination parameters instead')
  Future<List<Lead>> searchLeadsOld(String query) async {
    final response =
        await _apiService.get('/leads/search', queryParams: {'query': query});
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  Future<List<Lead>> getOverdueFollowUps() async {
    final response = await _apiService.get('/leads/overdue-followups');
    return _apiService.unwrapList<Lead>(
        response, (json) => Lead.fromJson(json));
  }

  Future<List<ActivityFeed>> getLeadActivities(String leadId) async {
    final response = await _apiService.get('/leads/$leadId/activities');
    return _apiService.unwrapList<ActivityFeed>(
        response, (json) => ActivityFeed.fromJson(json));
  }

  Future<void> convertLead(
      String leadId, Map<String, dynamic> requestData) async {
    final response =
        await _apiService.post('/leads/$leadId/convert', data: requestData);
    _apiService.unwrap<void>(response, (_) {});
  }

  Future<List<LeadDocument>> getLeadDocuments(String leadId) async {
    final response = await _apiService.get('/api/leads/$leadId/documents');
    return _apiService.unwrapList<LeadDocument>(
        response, (json) => LeadDocument.fromJson(json));
  }

  /// Upload a document for a lead
  /// [leadId] - The lead ID
  /// [file] - The file to upload
  /// Upload a document for a lead
  /// Supports all platforms: Web, Android, iOS, Windows, macOS, Linux
  /// [leadId] - The lead ID
  /// [file] - File object (for mobile/desktop) or null (for web)
  /// [bytes] - File bytes (for web or fallback) or null (for mobile/desktop with path)
  /// [fileName] - File name (required for all platforms)
  /// [categoryId] - Optional category ID (use null if no category)
  /// [description] - Optional description
  Future<LeadDocument> uploadDocument(
      String leadId, 
      File? file, 
      int? categoryId, 
      String? description, {
      Uint8List? bytes,
      String? fileName,
    }) async {
    MultipartFile multipartFile;
    String finalFileName;

    // Determine which method to use based on available data
    // Priority: bytes (web) > file path (mobile/desktop)
    if (bytes != null && fileName != null) {
      // Web platform or desktop with bytes available
      multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      );
      finalFileName = fileName;
    } else if (file != null) {
      // Mobile/Desktop platform with file path
      finalFileName = fileName ?? file.path.split(RegExp(r'[/\\]')).last;
      multipartFile = await MultipartFile.fromFile(file.path, filename: finalFileName);
    } else {
      // Error: neither bytes nor file provided
      throw Exception(
        'Either bytes+fileName (for web) or file (for mobile/desktop) must be provided'
      );
    }
    
    FormData formData = FormData.fromMap({
      'file': multipartFile,
      if (description != null && description.isNotEmpty) 'description': description,
      if (categoryId != null) 'categoryId': categoryId,
    });

    final response =
        await _apiService.post('/api/leads/$leadId/documents', data: formData);
    return _apiService.unwrap<LeadDocument>(response,
        (json) => LeadDocument.fromJson(json as Map<String, dynamic>));
  }

  /// Delete a document
  Future<void> deleteDocument(int documentId) async {
    final response = await _apiService.delete('/api/leads/documents/$documentId');
    _apiService.unwrap<void>(response, (_) {});
  }

  /// Get all document categories
  Future<List<DocumentCategory>> getDocumentCategories() async {
    final response = await _apiService.get('/api/leads/documents/categories');
    return _apiService.unwrapList<DocumentCategory>(
        response, (json) => DocumentCategory.fromJson(json));
  }

  Future<LeadInteraction> createInteraction(LeadInteraction interaction) async {
    final response = await _apiService.post('/leads/interactions',
        data: interaction.toJson());
    return _apiService.unwrap<LeadInteraction>(response,
        (json) => LeadInteraction.fromJson(json as Map<String, dynamic>));
  }

  /// Get score history for a lead
  Future<List<LeadScoreHistory>> getLeadScoreHistory(String leadId) async {
    final response = await _apiService.get('/leads/$leadId/score-history');
    return _apiService.unwrapList<LeadScoreHistory>(
        response, (json) => LeadScoreHistory.fromJson(json));
  }

  /// NEW: Standardized search endpoint for lead interactions
  Future<PaginatedResponse<LeadInteraction>> searchLeadInteractions({
    required int page,
    required int size,
    required String sortBy,
    required String sortDirection,
    String? search,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          if (value is DateTime) {
            queryParams[key] = value.toIso8601String().split('T')[0];
          } else {
            queryParams[key] = value.toString();
          }
        }
      });
    }

    final response = await _apiService.get('/leads/interactions/search',
        queryParams: queryParams);
    // Backend returns Page<LeadInteraction> (not wrapped in ApiResponse for this endpoint)
    // But handle both cases for safety
    return _apiService.unwrap<PaginatedResponse<LeadInteraction>>(
      response,
      (json) {
        Map<String, dynamic> pageData;
        if (json is Map<String, dynamic> && json.containsKey('data')) {
          pageData = json['data'] as Map<String, dynamic>;
        } else {
          pageData = json as Map<String, dynamic>;
        }
        return PaginatedResponse.fromJson(pageData, LeadInteraction.fromJson);
      },
    );
  }

  /// Export leads to Excel based on search filters
  /// Returns Excel file as bytes for download
  Future<Uint8List> exportLeadsToExcel({
    String? search,
    String? status,
    String? source,
    String? priority,
    String? customerType,
    String? projectType,
    String? assignedTeam,
    String? state,
    String? district,
    double? minBudget,
    double? maxBudget,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};

    // Add all filter parameters to queryParams
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (source != null && source.isNotEmpty) {
      queryParams['source'] = source;
    }
    if (priority != null && priority.isNotEmpty) {
      queryParams['priority'] = priority;
    }
    if (customerType != null && customerType.isNotEmpty) {
      queryParams['customerType'] = customerType;
    }
    if (projectType != null && projectType.isNotEmpty) {
      queryParams['projectType'] = projectType;
    }
    if (assignedTeam != null && assignedTeam.isNotEmpty) {
      queryParams['assignedTeam'] = assignedTeam;
    }
    if (state != null && state.isNotEmpty) {
      queryParams['state'] = state;
    }
    if (district != null && district.isNotEmpty) {
      queryParams['district'] = district;
    }
    if (minBudget != null) {
      queryParams['minBudget'] = minBudget;
    }
    if (maxBudget != null) {
      queryParams['maxBudget'] = maxBudget;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await _apiService.get(
      '/leads/export',
      queryParams: queryParams,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }
}

/// Document category model for lead documents
class DocumentCategory {
  final int id;
  final String name;
  final String? description;
  final int? displayOrder;

  DocumentCategory({
    required this.id,
    required this.name,
    this.description,
    this.displayOrder,
  });

  factory DocumentCategory.fromJson(Map<String, dynamic> json) {
    return DocumentCategory(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      displayOrder: json['displayOrder'] ?? json['display_order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'display_order': displayOrder,
    };
  }
}
