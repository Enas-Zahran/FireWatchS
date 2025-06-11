import 'package:flutter/material.dart';
import 'package:FireWatch/manager/managerTasks/addManagerReports/addEmergency.dart';
import 'package:FireWatch/manager/managerTasks/addManagerReports/addCorrective.dart';
import 'package:FireWatch/manager/managerTasks/approvalTasks.dart';
import 'package:FireWatch/manager/managerTasks/periodicManager.dart';
import 'package:FireWatch/manager/managerTasks/correctiveManager.dart';
import 'package:FireWatch/manager/managerTasks/emergencyManager.dart';
import 'package:FireWatch/manager/managerTasks/notificationsManager.dart';
class TasksMainPage extends StatelessWidget {
  static const String routeName = 'tasksMainPage';

  const TasksMainPage({super.key});

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('اضافة طارئ'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEmergencyTaskManagerPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.build),
                title: const Text('اضافة علاجي'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCorrectiveTaskManagerPage(),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff00408b),
        title: const Center(
          child: Text('لوحة المهام', style: TextStyle(color: Colors.white)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              //PendingEmergencyRequestsPage
 Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PendingEmergencyRequestsPage(),
                    ),
                  );            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddOptions(context),
          ),
          IconButton(
  icon: const Icon(Icons.notifications, color: Colors.white),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
  },
),
        ],
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
            title: 'دوري',
            icon: Icons.access_time,
             destinationPage: const PeriodicTasksPage(),
            
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'علاجي',
            icon: Icons.healing,
           destinationPage:  CorrectiveTasksPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'طارئ',
            icon: Icons.report,
           destinationPage:  EmergencyTasksPage(),
          ),
        ],
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
