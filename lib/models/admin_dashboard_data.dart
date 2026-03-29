class AdminDashboardData {
  final int pendingCount;
  final int assignedCount;
  final int completedCount;
  final int warrantyClaimsCount;
  final int customerCount;
  final int technicianCount;
  final Map<String, double> monthlyRevenue; // Month Name -> Revenue

  AdminDashboardData({
    required this.pendingCount,
    required this.assignedCount,
    required this.completedCount,
    required this.warrantyClaimsCount,
    required this.customerCount,
    required this.technicianCount,
    required this.monthlyRevenue,
  });
}
