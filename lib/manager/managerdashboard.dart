

import 'package:flutter/material.dart';
import 'package:FireWatch/manager/missions/add_edit_page.dart';
import 'package:FireWatch/manager/missions/reports_page.dart';
import 'package:FireWatch/manager/missions/tasks_page.dart'; 

class ManagerDashboard extends StatelessWidget {
  static const String managerDashboardRoute = 'managerdashboard';

  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff00408b),
        title: const Center(
          child: Text(
            'لوحة تحكم مدير دائرة السلامة',
            style: TextStyle(color: Colors.white),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: const Text('تأكيد'),
                    content: const Text('هل أنت متأكد من الرجوع لصفحة الدخول؟'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('إلغاء'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('نعم'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
        children: [
          _buildTile(
            context,
            title: 'المهام',
            icon: Icons.task_alt,
            destination: const TasksPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'إضافة وتعديل',
            icon: Icons.edit,
            destination: const AddEditPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'التقارير',
            icon: Icons.insert_chart,
            destination: const ReportsPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget destination,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
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
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
