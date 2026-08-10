import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/ai_models.dart';
import 'api_client.dart';

class AiService {
  final ApiClient _client;

  AiService(this._client);

  // ─── 1. Parse expense from natural language ───────────────────────────────
  Future<ParsedExpense> parseExpense(String text) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/ai/parse-expense',
      data: {'text': text},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return ParsedExpense.fromJson(data);
  }

  // ─── 2. Create expense from natural language (saves to DB) ───────────────
  Future<void> createExpenseFromText({
    required String businessId,
    required String text,
    String language = 'ar',
  }) async {
    await _client.post<Map<String, dynamic>>(
      '/expenses/from-text',
      data: {'business': businessId, 'text': text, 'language': language},
    );
  }

  // ─── 3. Business summary (week | month) ──────────────────────────────────
  Future<AiBusinessSummary> getBusinessSummary({
    required String businessId,
    String period = 'week',
    String language = 'ar',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/ai/summary/$businessId',
      queryParameters: {'period': period, 'language': language},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return AiBusinessSummary.fromJson(data);
  }

  // ─── 4. Anomaly detection ─────────────────────────────────────────────────
  Future<List<AiAnomaly>> detectAnomalies({
    required String businessId,
    String language = 'ar',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/ai/anomalies/$businessId',
      queryParameters: {'language': language},
    );
    final list = response.data!['data'] as List<dynamic>;
    return list
        .map((e) => AiAnomaly.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── 5. Dashboard insights ────────────────────────────────────────────────
  Future<List<AiInsight>> getInsights({
    required String businessId,
    String language = 'ar',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/ai/insights/$businessId',
      queryParameters: {'language': language},
    );
    final list = response.data!['data'] as List<dynamic>;
    return list
        .map((e) => AiInsight.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── 6. AI Chat ───────────────────────────────────────────────────────────
  Future<String> chat({
    required String businessId,
    required String message,
    String language = 'ar',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/ai/chat/$businessId',
      data: {'message': message, 'language': language},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return data['reply'] as String;
  }

  // ─── 7. Receipt image analysis ───────────────────────────────────────────
  Future<ReceiptAnalysis> analyzeReceipt(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    final response = await _client.post<Map<String, dynamic>>(
      '/ai/analyze-receipt',
      data: {'base64Image': base64Image, 'mimeType': mimeType},
    );
    return ReceiptAnalysis.fromJson(response.data!);
  }

  // ─── 8. Product / profit analysis ────────────────────────────────────────
  Future<AiProductAnalysis> analyzeProducts({
    required String businessId,
    String language = 'ar',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/ai/product-analysis/$businessId',
      queryParameters: {'language': language},
    );
    return AiProductAnalysis.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  // ─── 9. What-if pricing simulator ────────────────────────────────────────
  Future<PricingSimulation> simulatePricing({
    required String businessId,
    String? productId,
    required String productName,
    required double currentPrice,
    required double newPrice,
    String language = 'ar',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/ai/simulate-pricing/$businessId',
      data: {
        if (productId != null) 'productId': productId,
        'productName': productName,
        'currentPrice': currentPrice,
        'newPrice': newPrice,
        'language': language,
      },
    );
    return PricingSimulation.fromJson(response.data!);
  }

  // ─── 10. Pricing & sales advice ──────────────────────────────────────────
  Future<AiPricingAdvice> getPricingAdvice({
    required String businessId,
    String language = 'ar',
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/ai/pricing-advice/$businessId',
      queryParameters: {'language': language},
    );
    return AiPricingAdvice.fromJson(response.data!);
  }
}
