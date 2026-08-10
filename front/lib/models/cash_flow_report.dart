class CashFlowReport {
  final String period;
  final double cashIn;
  final double cashOut;
  final double netCashFlow;
  final double nonCashLosses;

  CashFlowReport({
    required this.period,
    required this.cashIn,
    required this.cashOut,
    required this.netCashFlow,
    required this.nonCashLosses,
  });

  factory CashFlowReport.fromJson(Map<String, dynamic> json) {
    return CashFlowReport(
      period: json['period']?.toString() ?? '',
      cashIn: (json['cashIn'] as num? ?? 0).toDouble(),
      cashOut: (json['cashOut'] as num? ?? 0).toDouble(),
      netCashFlow: (json['net'] as num? ?? json['netCashFlow'] as num? ?? 0).toDouble(),
      nonCashLosses: (json['nonCashLoss'] as num? ?? json['nonCashLosses'] as num? ?? 0).toDouble(),
    );
  }
}

class CashFlowSummary {
  final double totalCashIn;
  final double totalCashOut;
  final double netCashFlow;
  final double nonCashLosses;
  final List<CashFlowReport> periods;

  CashFlowSummary({
    required this.totalCashIn,
    required this.totalCashOut,
    required this.netCashFlow,
    required this.nonCashLosses,
    required this.periods,
  });

  factory CashFlowSummary.fromJson(Map<String, dynamic> json) {
    // Backend returns: { period: {...}, summary: {...}, breakdown: [...] }
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final breakdownData = json['breakdown'] as List? ?? [];
    
    final periods = breakdownData
        .map((p) => CashFlowReport.fromJson(p as Map<String, dynamic>))
        .toList();

    return CashFlowSummary(
      totalCashIn: (summary['totalCashIn'] as num? ?? 0).toDouble(),
      totalCashOut: (summary['totalCashOut'] as num? ?? 0).toDouble(),
      netCashFlow: (summary['netCashFlow'] as num? ?? 0).toDouble(),
      nonCashLosses: (summary['nonCashLosses'] as num? ?? 0).toDouble(),
      periods: periods,
    );
  }
}
