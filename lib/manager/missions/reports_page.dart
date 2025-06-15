import 'package:flutter/material.dart';

class ReportsDashboardPage extends StatelessWidget {
  static const routeName = 'reportsDashboard';

  const ReportsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text('لوحة التقارير', style: TextStyle(color: Colors.white)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 70, 30, 30),
          children: [
            _buildTile(
              context,
              title: 'الأعمال',
              icon: Icons.assignment_turned_in,
              onTap: () {
                // TODO: Navigate to الأعمال reports page
                // Navigator.push(context, MaterialPageRoute(builder: (_) => YourWorkReportsPage()));
              },
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              title: 'المالية',
              icon: Icons.attach_money,
              onTap: () {
                // TODO: Navigate to المالية reports page
                // Navigator.push(context, MaterialPageRoute(builder: (_) => YourFinancialReportsPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
