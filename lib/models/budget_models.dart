/// Budget vs Actuals Summary model
class BudgetSummary {
  final int projectId;
  final double totalBudget;
  final double totalActual;
  final double variance;
  final double consumedPercentage;
  final String status;
  final List<BoqItemActual> items;

  BudgetSummary({
    required this.projectId,
    required this.totalBudget,
    required this.totalActual,
    required this.variance,
    required this.consumedPercentage,
    required this.status,
    required this.items,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      projectId: json['projectId'] ?? 0,
      totalBudget: (json['totalBudget'] ?? 0).toDouble(),
      totalActual: (json['totalActual'] ?? 0).toDouble(),
      variance: (json['variance'] ?? 0).toDouble(),
      consumedPercentage: (json['consumedPercentage'] ?? 0).toDouble(),
      status: json['status'] ?? 'ON_TRACK',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BoqItemActual.fromJson(e))
              .toList() ??
          [],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'ON_TRACK':
        return 'On Track';
      case 'NEAR_LIMIT':
        return 'Near Limit';
      case 'OVER_BUDGET':
        return 'Over Budget';
      default:
        return status;
    }
  }

  bool get isHealthy => status == 'ON_TRACK';
  bool get isWarning => status == 'NEAR_LIMIT';
  bool get isCritical => status == 'OVER_BUDGET';
}

/// Individual BOQ Item with actual consumption
class BoqItemActual {
  final int boqItemId;
  final String description;
  final String workType;
  final String? unit;
  final double budgetQty;
  final double budgetAmount;
  final double actualQty;
  final double actualAmount;
  final double variance;
  final double consumedPercentage;
  final String status;

  BoqItemActual({
    required this.boqItemId,
    required this.description,
    required this.workType,
    this.unit,
    required this.budgetQty,
    required this.budgetAmount,
    required this.actualQty,
    required this.actualAmount,
    required this.variance,
    required this.consumedPercentage,
    required this.status,
  });

  factory BoqItemActual.fromJson(Map<String, dynamic> json) {
    return BoqItemActual(
      boqItemId: json['boqItemId'] ?? 0,
      description: json['description'] ?? '',
      workType: json['workType'] ?? '',
      unit: json['unit'],
      budgetQty: (json['budgetQty'] ?? 0).toDouble(),
      budgetAmount: (json['budgetAmount'] ?? 0).toDouble(),
      actualQty: (json['actualQty'] ?? 0).toDouble(),
      actualAmount: (json['actualAmount'] ?? 0).toDouble(),
      variance: (json['variance'] ?? 0).toDouble(),
      consumedPercentage: (json['consumedPercentage'] ?? 0).toDouble(),
      status: json['status'] ?? 'ON_TRACK',
    );
  }

  bool get isOverBudget => status == 'OVER_BUDGET';
  bool get isNearLimit => status == 'NEAR_LIMIT';
}

/// Project Profit/Loss Summary
class ProjectPLSummary {
  final int projectId;
  final double totalRevenue;
  final double materialCost;
  final double labourCost;
  final double totalExpenses;
  final double grossProfit;
  final double profitMarginPercentage;
  final String status;

  ProjectPLSummary({
    required this.projectId,
    required this.totalRevenue,
    required this.materialCost,
    required this.labourCost,
    required this.totalExpenses,
    required this.grossProfit,
    required this.profitMarginPercentage,
    required this.status,
  });

  factory ProjectPLSummary.fromJson(Map<String, dynamic> json) {
    return ProjectPLSummary(
      projectId: json['projectId'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      materialCost: (json['materialCost'] ?? 0).toDouble(),
      labourCost: (json['labourCost'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      grossProfit: (json['grossProfit'] ?? 0).toDouble(),
      profitMarginPercentage:
          (json['profitMarginPercentage'] ?? 0).toDouble(),
      status: json['status'] ?? 'PROFIT',
    );
  }

  bool get isProfit => status == 'PROFIT';
  bool get isLoss => status == 'LOSS';
}

/// Project Health Summary
class ProjectHealthSummary {
  final int totalPhases;
  final int completedPhases;
  final int delayedPhases;
  final int totalDelayLogs;
  final int approvedVariations;
  final double variationAmount;
  final String overallStatus;

  ProjectHealthSummary({
    required this.totalPhases,
    required this.completedPhases,
    required this.delayedPhases,
    required this.totalDelayLogs,
    required this.approvedVariations,
    required this.variationAmount,
    required this.overallStatus,
  });

  factory ProjectHealthSummary.fromJson(Map<String, dynamic> json) {
    return ProjectHealthSummary(
      totalPhases: json['totalPhases'] ?? 0,
      completedPhases: json['completedPhases'] ?? 0,
      delayedPhases: json['delayedPhases'] ?? 0,
      totalDelayLogs: json['totalDelayLogs'] ?? 0,
      approvedVariations: json['approvedVariations'] ?? 0,
      variationAmount: (json['variationAmount'] ?? 0).toDouble(),
      overallStatus: json['overallStatus'] ?? 'NOT_STARTED',
    );
  }

  double get completionPercentage {
    if (totalPhases == 0) return 0;
    return (completedPhases / totalPhases) * 100;
  }

  String get statusDisplay {
    switch (overallStatus) {
      case 'ON_TRACK':
        return 'On Track';
      case 'MINOR_DELAYS':
        return 'Minor Delays';
      case 'AT_RISK':
        return 'At Risk';
      case 'NOT_STARTED':
        return 'Not Started';
      default:
        return overallStatus;
    }
  }
}
