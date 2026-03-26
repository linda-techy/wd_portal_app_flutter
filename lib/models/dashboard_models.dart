// Dashboard data models — mirrors the 5 DashboardXxxDTO Java classes

class DashboardOverview {
  final int totalActiveProjects;
  final int totalLeads;
  final int openLeads;
  final double revenueCollected;
  final double revenueTarget;
  final double pendingPayments;
  final int overdueProjects;
  final int tasksDueToday;
  final int overdueTasks;

  const DashboardOverview({
    required this.totalActiveProjects,
    required this.totalLeads,
    required this.openLeads,
    required this.revenueCollected,
    required this.revenueTarget,
    required this.pendingPayments,
    required this.overdueProjects,
    required this.tasksDueToday,
    required this.overdueTasks,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalActiveProjects: (json['totalActiveProjects'] as num?)?.toInt() ?? 0,
      totalLeads: (json['totalLeads'] as num?)?.toInt() ?? 0,
      openLeads: (json['openLeads'] as num?)?.toInt() ?? 0,
      revenueCollected: (json['revenueCollected'] as num?)?.toDouble() ?? 0.0,
      revenueTarget: (json['revenueTarget'] as num?)?.toDouble() ?? 0.0,
      pendingPayments: (json['pendingPayments'] as num?)?.toDouble() ?? 0.0,
      overdueProjects: (json['overdueProjects'] as num?)?.toInt() ?? 0,
      tasksDueToday: (json['tasksDueToday'] as num?)?.toInt() ?? 0,
      overdueTasks: (json['overdueTasks'] as num?)?.toInt() ?? 0,
    );
  }

  static DashboardOverview empty() => const DashboardOverview(
        totalActiveProjects: 0,
        totalLeads: 0,
        openLeads: 0,
        revenueCollected: 0,
        revenueTarget: 0,
        pendingPayments: 0,
        overdueProjects: 0,
        tasksDueToday: 0,
        overdueTasks: 0,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardProjects {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int onHoldProjects;
  final int overdueProjects;
  final Map<String, int> byPhase;
  final Map<String, int> byStatus;
  final double totalBudget;
  final double averageBudget;
  final double totalSqfeet;
  final List<ProjectHealthItem> atRisk;

  const DashboardProjects({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.onHoldProjects,
    required this.overdueProjects,
    required this.byPhase,
    required this.byStatus,
    required this.totalBudget,
    required this.averageBudget,
    required this.totalSqfeet,
    required this.atRisk,
  });

  factory DashboardProjects.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
    }

    return DashboardProjects(
      totalProjects: (json['totalProjects'] as num?)?.toInt() ?? 0,
      activeProjects: (json['activeProjects'] as num?)?.toInt() ?? 0,
      completedProjects: (json['completedProjects'] as num?)?.toInt() ?? 0,
      onHoldProjects: (json['onHoldProjects'] as num?)?.toInt() ?? 0,
      overdueProjects: (json['overdueProjects'] as num?)?.toInt() ?? 0,
      byPhase: parseMap(json['byPhase']),
      byStatus: parseMap(json['byStatus']),
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? 0.0,
      averageBudget: (json['averageBudget'] as num?)?.toDouble() ?? 0.0,
      totalSqfeet: (json['totalSqfeet'] as num?)?.toDouble() ?? 0.0,
      atRisk: (json['atRisk'] as List<dynamic>?)
              ?.map((e) => ProjectHealthItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static DashboardProjects empty() => const DashboardProjects(
        totalProjects: 0,
        activeProjects: 0,
        completedProjects: 0,
        onHoldProjects: 0,
        overdueProjects: 0,
        byPhase: {},
        byStatus: {},
        totalBudget: 0,
        averageBudget: 0,
        totalSqfeet: 0,
        atRisk: [],
      );
}

class ProjectHealthItem {
  final int projectId;
  final String projectName;
  final int overdueTasks;
  final int activeDelays;
  final double? budgetUtilizationPct;

  const ProjectHealthItem({
    required this.projectId,
    required this.projectName,
    required this.overdueTasks,
    required this.activeDelays,
    this.budgetUtilizationPct,
  });

  factory ProjectHealthItem.fromJson(Map<String, dynamic> json) {
    return ProjectHealthItem(
      projectId: (json['projectId'] as num).toInt(),
      projectName: json['projectName'] as String? ?? '',
      overdueTasks: (json['overdueTasks'] as num?)?.toInt() ?? 0,
      activeDelays: (json['activeDelays'] as num?)?.toInt() ?? 0,
      budgetUtilizationPct: (json['budgetUtilizationPct'] as num?)?.toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardLeads {
  final int totalLeads;
  final int newLeads;
  final int hotLeads;
  final double conversionRate;
  final double pipelineValue;
  final Map<String, int> byStatus;
  final Map<String, int> bySource;
  final List<MonthlyCount> monthlyTrend;

  const DashboardLeads({
    required this.totalLeads,
    required this.newLeads,
    required this.hotLeads,
    required this.conversionRate,
    required this.pipelineValue,
    required this.byStatus,
    required this.bySource,
    required this.monthlyTrend,
  });

  factory DashboardLeads.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
    }

    return DashboardLeads(
      totalLeads: (json['totalLeads'] as num?)?.toInt() ?? 0,
      newLeads: (json['newLeads'] as num?)?.toInt() ?? 0,
      hotLeads: (json['hotLeads'] as num?)?.toInt() ?? 0,
      conversionRate: (json['conversionRate'] as num?)?.toDouble() ?? 0.0,
      pipelineValue: (json['pipelineValue'] as num?)?.toDouble() ?? 0.0,
      byStatus: parseMap(json['byStatus']),
      bySource: parseMap(json['bySource']),
      monthlyTrend: (json['monthlyTrend'] as List<dynamic>?)
              ?.map((e) => MonthlyCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static DashboardLeads empty() => const DashboardLeads(
        totalLeads: 0,
        newLeads: 0,
        hotLeads: 0,
        conversionRate: 0,
        pipelineValue: 0,
        byStatus: {},
        bySource: {},
        monthlyTrend: [],
      );
}

class MonthlyCount {
  final String month; // yyyy-MM
  final int count;

  const MonthlyCount({required this.month, required this.count});

  factory MonthlyCount.fromJson(Map<String, dynamic> json) => MonthlyCount(
        month: json['month'] as String,
        count: (json['count'] as num).toInt(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardFinance {
  final double revenueCollected;
  final double revenueInvoiced;
  final double revenueTarget;
  final double labourCost;
  final double procurementCost;
  final double subcontractCost;
  final double totalCost;
  final double grossMargin;
  final double grossMarginPct;
  final List<MonthlyRevenue> monthlyRevenue;
  final Map<String, int> paymentsByStatus;

  const DashboardFinance({
    required this.revenueCollected,
    required this.revenueInvoiced,
    required this.revenueTarget,
    required this.labourCost,
    required this.procurementCost,
    required this.subcontractCost,
    required this.totalCost,
    required this.grossMargin,
    required this.grossMarginPct,
    required this.monthlyRevenue,
    required this.paymentsByStatus,
  });

  factory DashboardFinance.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      );
    }

    return DashboardFinance(
      revenueCollected: (json['revenueCollected'] as num?)?.toDouble() ?? 0.0,
      revenueInvoiced: (json['revenueInvoiced'] as num?)?.toDouble() ?? 0.0,
      revenueTarget: (json['revenueTarget'] as num?)?.toDouble() ?? 0.0,
      labourCost: (json['labourCost'] as num?)?.toDouble() ?? 0.0,
      procurementCost: (json['procurementCost'] as num?)?.toDouble() ?? 0.0,
      subcontractCost: (json['subcontractCost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      grossMargin: (json['grossMargin'] as num?)?.toDouble() ?? 0.0,
      grossMarginPct: (json['grossMarginPct'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthlyRevenue'] as List<dynamic>?)
              ?.map((e) => MonthlyRevenue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentsByStatus: parseMap(json['paymentsByStatus']),
    );
  }

  static DashboardFinance empty() => const DashboardFinance(
        revenueCollected: 0,
        revenueInvoiced: 0,
        revenueTarget: 0,
        labourCost: 0,
        procurementCost: 0,
        subcontractCost: 0,
        totalCost: 0,
        grossMargin: 0,
        grossMarginPct: 0,
        monthlyRevenue: [],
        paymentsByStatus: {},
      );
}

class MonthlyRevenue {
  final String month;
  final double collected;
  final double invoiced;

  const MonthlyRevenue({
    required this.month,
    required this.collected,
    required this.invoiced,
  });

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) => MonthlyRevenue(
        month: json['month'] as String,
        collected: (json['collected'] as num?)?.toDouble() ?? 0.0,
        invoiced: (json['invoiced'] as num?)?.toDouble() ?? 0.0,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardOperations {
  final int labourOnSiteToday;
  final int siteReportsThisWeek;
  final int totalOverdueTasks;
  final int tasksDueToday;
  final int openObservations;
  final int pendingApprovals;
  final int activeDelays;

  const DashboardOperations({
    required this.labourOnSiteToday,
    required this.siteReportsThisWeek,
    required this.totalOverdueTasks,
    required this.tasksDueToday,
    required this.openObservations,
    required this.pendingApprovals,
    required this.activeDelays,
  });

  factory DashboardOperations.fromJson(Map<String, dynamic> json) {
    return DashboardOperations(
      labourOnSiteToday: (json['labourOnSiteToday'] as num?)?.toInt() ?? 0,
      siteReportsThisWeek: (json['siteReportsThisWeek'] as num?)?.toInt() ?? 0,
      totalOverdueTasks: (json['totalOverdueTasks'] as num?)?.toInt() ?? 0,
      tasksDueToday: (json['tasksDueToday'] as num?)?.toInt() ?? 0,
      openObservations: (json['openObservations'] as num?)?.toInt() ?? 0,
      pendingApprovals: (json['pendingApprovals'] as num?)?.toInt() ?? 0,
      activeDelays: (json['activeDelays'] as num?)?.toInt() ?? 0,
    );
  }

  static DashboardOperations empty() => const DashboardOperations(
        labourOnSiteToday: 0,
        siteReportsThisWeek: 0,
        totalOverdueTasks: 0,
        tasksDueToday: 0,
        openObservations: 0,
        pendingApprovals: 0,
        activeDelays: 0,
      );
}

// ─── Composite wrapper ────────────────────────────────────────────────────────

class DashboardData {
  final DashboardOverview overview;
  final DashboardProjects projects;
  final DashboardLeads leads;
  final DashboardFinance finance;
  final DashboardOperations operations;

  const DashboardData({
    required this.overview,
    required this.projects,
    required this.leads,
    required this.finance,
    required this.operations,
  });

  static DashboardData empty() => DashboardData(
        overview: DashboardOverview.empty(),
        projects: DashboardProjects.empty(),
        leads: DashboardLeads.empty(),
        finance: DashboardFinance.empty(),
        operations: DashboardOperations.empty(),
      );
}
