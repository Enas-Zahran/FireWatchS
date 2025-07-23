import 'package:flutter/material.dart';
import 'package:FireWatch/manager/managerReports/ManagerReportsCorrectiveEmergency/Corrective.dart';
import 'package:FireWatch/manager/managerReports/ManagerReportsCorrectiveEmergency/Emergency.dart';
import 'package:FireWatch/My/BuildTile.dart';
class ApprovedReportsDashboardPage extends StatelessWidget {
  static const String routeName = 'approvedReportsDashboardPage';

  const ApprovedReportsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text('لوحة التقارير المعتمدة', style: TextStyle(color: Colors.white)),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
          children: [
            BuildTile(
              
              title: 'التقارير الطارئة المعتمدة',
              icon: Icons.warning_amber_rounded,
              destination: const ApprovedEmergencyTasksPage(),
            ),
            const SizedBox(height: 12),
            BuildTile(
             
              title: 'التقارير العلاجية المعتمدة',
              icon: Icons.local_hospital,
              destination: const ApprovedCorrectiveTasksPage(),
            ),
          ],
        ),
      ),
    );
  }

 
  
  }

