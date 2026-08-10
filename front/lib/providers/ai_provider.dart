import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_models.dart';
import 'service_providers.dart';
import 'business_provider.dart';
import 'theme_provider.dart';

// ─── helpers ──────────────────────────────────────────────────────────────────
String _lang(Ref ref) => ref.watch(languageProvider);

// ─── 1. Anomaly detection (auto-runs when businessId changes) ─────────────────
final aiAnomaliesProvider =
    FutureProvider.autoDispose<List<AiAnomaly>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  return ref
      .watch(aiServiceProvider)
      .detectAnomalies(businessId: businessId, language: _lang(ref));
});

// ─── 2. Dashboard insights ────────────────────────────────────────────────────
final aiInsightsProvider =
    FutureProvider.autoDispose<List<AiInsight>>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return [];
  return ref
      .watch(aiServiceProvider)
      .getInsights(businessId: businessId, language: _lang(ref));
});

// ─── 3. Business summary ──────────────────────────────────────────────────────
final aiSummaryPeriodProvider = StateProvider<String>((ref) => 'month');

final aiBusinessSummaryProvider =
    FutureProvider.autoDispose<AiBusinessSummary?>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return null;
  final period = ref.watch(aiSummaryPeriodProvider);
  return ref.watch(aiServiceProvider).getBusinessSummary(
        businessId: businessId,
        period: period,
        language: _lang(ref),
      );
});

// ─── 4. Product analysis ──────────────────────────────────────────────────────
final aiProductAnalysisProvider =
    FutureProvider.autoDispose<AiProductAnalysis?>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return null;
  return ref
      .watch(aiServiceProvider)
      .analyzeProducts(businessId: businessId, language: _lang(ref));
});

// ─── 4b. Pricing & sales advice ───────────────────────────────────────────────
final aiPricingAdviceProvider =
    FutureProvider.autoDispose<AiPricingAdvice?>((ref) async {
  final businessId = ref.watch(activeBusinessIdProvider);
  if (businessId == null) return null;
  return ref
      .watch(aiServiceProvider)
      .getPricingAdvice(businessId: businessId, language: _lang(ref));
});

// ─── 5. NL expense parse state (ephemeral — not auto-fetched) ─────────────────
class ParsedExpenseState {
  final bool isLoading;
  final ParsedExpense? result;
  final String? error;

  const ParsedExpenseState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  ParsedExpenseState copyWith({
    bool? isLoading,
    ParsedExpense? result,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      ParsedExpenseState(
        isLoading: isLoading ?? this.isLoading,
        result: clearResult ? null : (result ?? this.result),
        error: clearError ? null : (error ?? this.error),
      );
}

class NlExpenseNotifier extends StateNotifier<ParsedExpenseState> {
  final Ref _ref;
  NlExpenseNotifier(this._ref) : super(const ParsedExpenseState());

  Future<void> parse(String text) async {
    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);
    try {
      final result =
          await _ref.read(aiServiceProvider).parseExpense(text);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString(), clearResult: true);
    }
  }

  Future<bool> confirm({
    required String businessId,
    required String originalText,
  }) async {
    if (state.result == null) return false;
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(aiServiceProvider).createExpenseFromText(
            businessId: businessId,
            text: originalText,
          );
      reset();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() => state = const ParsedExpenseState();
}

final nlExpenseProvider =
    StateNotifierProvider.autoDispose<NlExpenseNotifier, ParsedExpenseState>(
        (ref) => NlExpenseNotifier(ref));

// ─── 6. Chat message list ─────────────────────────────────────────────────────
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;
  ChatNotifier(this._ref) : super([]);

  bool _sending = false;
  bool get isSending => _sending;

  Future<void> send(String text, String businessId) async {
    if (text.trim().isEmpty) return;
    _sending = true;
    state = [
      ...state,
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    ];
    try {
      final reply = await _ref.read(aiServiceProvider).chat(
            businessId: businessId,
            message: text,
            language: _ref.read(languageProvider),
          );
      state = [
        ...state,
        ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()),
      ];
    } catch (e) {
      state = [
        ...state,
        ChatMessage(
            text: '⚠️ ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now()),
      ];
    } finally {
      _sending = false;
    }
  }

  void clear() => state = [];
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
        (ref) => ChatNotifier(ref));

// ─── 7. Pricing simulator state ───────────────────────────────────────────────
class PricingSimState {
  final bool isLoading;
  final PricingSimulation? result;
  final String? error;

  const PricingSimState(
      {this.isLoading = false, this.result, this.error});

  PricingSimState copyWith({
    bool? isLoading,
    PricingSimulation? result,
    String? error,
    bool clear = false,
  }) =>
      PricingSimState(
        isLoading: isLoading ?? this.isLoading,
        result: clear ? null : (result ?? this.result),
        error: clear ? null : (error ?? this.error),
      );
}

class PricingSimNotifier extends StateNotifier<PricingSimState> {
  final Ref _ref;
  PricingSimNotifier(this._ref) : super(const PricingSimState());

  Future<void> simulate({
    required String businessId,
    String? productId,
    required String productName,
    required double currentPrice,
    required double newPrice,
  }) async {
    state = state.copyWith(isLoading: true, clear: true);
    try {
      final result = await _ref.read(aiServiceProvider).simulatePricing(
            businessId: businessId,
            productId: productId,
            productName: productName,
            currentPrice: currentPrice,
            newPrice: newPrice,
            language: _ref.read(languageProvider),
          );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const PricingSimState();
}

final pricingSimProvider =
    StateNotifierProvider.autoDispose<PricingSimNotifier, PricingSimState>(
        (ref) => PricingSimNotifier(ref));

// ─── 8. Receipt analysis state ────────────────────────────────────────────────
class ReceiptState {
  final bool isLoading;
  final ReceiptAnalysis? result;
  final String? error;

  const ReceiptState(
      {this.isLoading = false, this.result, this.error});

  ReceiptState copyWith({
    bool? isLoading,
    ReceiptAnalysis? result,
    String? error,
    bool clear = false,
  }) =>
      ReceiptState(
        isLoading: isLoading ?? this.isLoading,
        result: clear ? null : (result ?? this.result),
        error: clear ? null : (error ?? this.error),
      );
}

class ReceiptNotifier extends StateNotifier<ReceiptState> {
  final Ref _ref;
  ReceiptNotifier(this._ref) : super(const ReceiptState());

  Future<void> analyze(dynamic imageFile) async {
    state = state.copyWith(isLoading: true, clear: true);
    try {
      final result =
          await _ref.read(aiServiceProvider).analyzeReceipt(imageFile);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const ReceiptState();
}

final receiptProvider =
    StateNotifierProvider.autoDispose<ReceiptNotifier, ReceiptState>(
        (ref) => ReceiptNotifier(ref));
