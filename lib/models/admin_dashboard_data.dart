class AdminDashboardData {
  final int pendingCount;
  final int assignedCount;
  final int completedCount;
  final int warrantyClaimsCount;
  final int customerCount;
  final int technicianCount;
  final Map<String, double> monthlyRevenue; // Month Name -> Revenue
  final Map<String, double> revenue7Days; // Date -> Revenue
  final Map<String, double> revenue30Days; // Date -> Revenue
  final Map<String, double> revenue12Months; // Month -> Revenue
  final double totalRevenue; // Overall total revenue
  final List<Map<String, dynamic>> rawRevenueData;

  AdminDashboardData({
    required this.pendingCount,
    required this.assignedCount,
    required this.completedCount,
    required this.warrantyClaimsCount,
    required this.customerCount,
    required this.technicianCount,
    required this.monthlyRevenue,
    required this.revenue7Days,
    required this.revenue30Days,
    required this.revenue12Months,
    required this.totalRevenue,
    required this.rawRevenueData,
  });
}
