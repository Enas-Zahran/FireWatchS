import 'package:flutter/material.dart';
import 'package:FireWatch/manager/managerReports/managerPeriodicReport.dart';
import 'package:FireWatch/manager/managerReports/managerCorrectiveReport.dart';
import 'package:FireWatch/manager/managerReports/managerEmergencyReport.dart';
class ManagerReportsDashboardPage extends StatelessWidget {
  static const String routeName = 'managerReportsDashboardPage';

  const ManagerReportsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text('لوحة تقارير المهام', style: TextStyle(color: Colors.white)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
          children: [
            _buildTile(
              context,
              title: 'التقارير الدورية',
              icon: Icons.access_time,
              destinationPage: const ManagerPeriodicReports(),
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              title: 'التقارير العلاجية',
              icon: Icons.healing,
              destinationPage: const ManagerCorrectiveReports(),
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              title: 'التقارير الطارئة',
              icon: Icons.report,
              destinationPage: const ManagerEmergencyReports(),
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
    required Widget destinationPage,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationPage),
          );
        },
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
