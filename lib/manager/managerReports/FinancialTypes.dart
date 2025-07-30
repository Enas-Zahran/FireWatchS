import 'package:flutter/material.dart';
import 'package:FireWatch/manager/managerReports/FinancialReports.dart';
import 'package:FireWatch/My/BuildTile.dart';
import 'package:FireWatch/manager/managerReports/maintenanceReports.dart';

class FinancialTypesPage extends StatelessWidget {
  static const routeName = 'reportsDashboard';

  const FinancialTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text(
              'لوحة التقارير المالية',
              style: TextStyle(color: Colors.white),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 120, 30, 30),
          children: [
            BuildTile(
              title: 'شراء الادوات',
              icon: Icons.shop,
              destination: FinancialReportsPage(),
            ),
            const SizedBox(height: 12),
            BuildTile(
              title: 'الاجرائات',
              icon: Icons.attach_money,
              destination: MaintenanceReportsPage(),
            ),
          ],
        ),
      ),
    );
  }
}
