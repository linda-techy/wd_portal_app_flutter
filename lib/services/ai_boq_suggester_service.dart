import 'api_service.dart';

/// One suggestion from the AI BOQ-item assistant.
///
/// Shape mirrors the backend `BoqSuggesterResponse` record. The four primary
/// fields (description, unit, hsnSacCode, itemKind) feed directly into the
/// BOQ create dialog; the trailing metadata (promptVersion, providerName,
/// token usage, latency) powers the "show how this was generated" affordance
/// so users can audit the suggestion before accepting it.
class BoqSuggestion {
  final String description;
  final String unit;
  final String hsnSacCode;
  final String itemKind;
  final String confidence;
  final String reasoning;
  final String promptVersion;
  final String providerName;
  final int inputTokens;
  final int outputTokens;
  final int latencyMs;

  const BoqSuggestion({
    required this.description,
    required this.unit,
    required this.hsnSacCode,
    required this.itemKind,
    required this.confidence,
    required this.reasoning,
    required this.promptVersion,
    required this.providerName,
    required this.inputTokens,
    required this.outputTokens,
    required this.latencyMs,
  });

  factory BoqSuggestion.fromJson(Map<String, dynamic> json) => BoqSuggestion(
        description: json['description'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        hsnSacCode: json['hsnSacCode'] as String? ?? '',
        itemKind: json['itemKind'] as String? ?? 'BASE',
        confidence: json['confidence'] as String? ?? 'medium',
        reasoning: json['reasoning'] as String? ?? '',
        promptVersion: json['promptVersion'] as String? ?? '',
        providerName: json['providerName'] as String? ?? '',
        inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
        outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
        latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
      );
}

/// Client for `POST /api/ai/boq/suggest`. The backend service is provider-
/// agnostic — the same call works whether the deployment is wired to the
/// stub, the scripted test harness, or the real Anthropic adapter (set
/// `ai.anthropic.enabled=true` server-side).
class AiBoqSuggesterService {
  AiBoqSuggesterService(this._api);

  final ApiService _api;

  Future<BoqSuggestion> suggest(String rawText) async {
    final response = await _api.dio.post(
      '/api/ai/boq/suggest',
      data: {'rawText': rawText.trim()},
    );
    final body = response.data;
    if (body is! Map || body['success'] != true) {
      throw Exception(body is Map
          ? (body['message']?.toString() ?? 'Suggestion failed')
          : 'Suggestion failed');
    }
    return BoqSuggestion.fromJson(
        Map<String, dynamic>.from(body['data'] as Map));
  }
}
