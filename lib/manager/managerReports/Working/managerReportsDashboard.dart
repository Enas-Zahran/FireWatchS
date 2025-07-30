import 'package:flutter/material.dart';
import 'package:FireWatch/manager/managerReports/Working/managerPeriodicReport.dart';
import 'package:FireWatch/manager/managerReports/Working/managerCorrectiveReport.dart';
import 'package:FireWatch/manager/managerReports/Working/managerEmergencyReport.dart';
import 'package:FireWatch/My/BuildTile.dart';
import 'package:FireWatch/manager/managerReports/Working/ManagerReportsCorrectiveEmergency/CorrectiveEmergencyDashboard.dart';
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
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.check),
                     onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ApprovedReportsDashboardPage()),
            );
          },
                  ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
          children: [
            BuildTile(
              
              title: 'التقارير الدورية',
              icon: Icons.access_time,
              destination: const ManagerPeriodicReports(),
            ),
            const SizedBox(height: 12),
            BuildTile(
              
              title: 'التقارير العلاجية',
              icon: Icons.healing,
              destination: const ManagerCorrectiveReports(),
            ),
            const SizedBox(height: 12),
          BuildTile(
             
              title: 'التقارير الطارئة',
              icon: Icons.report,
              destination: const ManagerEmergencyReports(),
            ),
          ],
        ),
      ),
    );
  }

  
}
