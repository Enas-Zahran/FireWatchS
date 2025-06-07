import 'package:flutter/material.dart';
import 'package:FireWatch/manager/priority/dawry_page.dart';
import 'package:FireWatch/manager/priority/elaji_page.dart';
import 'package:FireWatch/manager/priority/emergency.dart';
import 'package:FireWatch/All/addemergency.dart';

class TasksPage extends StatelessWidget {
  static const String tasksPageRoute = 'tasksPage';

  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff00408b),
        title: const Center(
          child: Text('لوحة المهام', style: TextStyle(color: Colors.white)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
            Navigator.pushNamed(context, AddEmergencyPage.addEmergencyRoute);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
        children: [
          _buildTile(
            context,
            title: 'دوري',
            icon: Icons.schedule,
            destination: const ManagerDawriPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'علاجي',
            icon: Icons.medical_services,
            destination: const ManagerElajiPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'طارئ',
            icon: Icons.warning,
            destination: const MangerEmergencyPage(),
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
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination),
            ),
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
