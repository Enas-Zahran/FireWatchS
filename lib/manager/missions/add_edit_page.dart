import 'package:flutter/material.dart';

import 'package:FireWatch/manager/managerAddEdit/UsersManger/usersManager.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/equipmentManager.dart';
import 'package:FireWatch/manager/managerAddEdit/pricesManager.dart';
import 'package:FireWatch/manager/managerAddEdit/locationManger.dart';

class AddEditPage extends StatelessWidget {
  static const String addEditDashboardRoute = 'addeditdashboard';

  const AddEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff00408b),
        title: const Center(
          child: Text(
            'لوحة الاضافة و التعديل',
            style: TextStyle(color: Colors.white),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
        children: [
          _buildTile(
            context,
            title: 'المستخدمين',
            icon: Icons.person,
            destination:  ManagerUserListPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'المعدات',
            icon: Icons.build,
            destination:  AllToolsPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'الأسعار',
            icon: Icons.attach_money,
            destination: const PricesPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'الأماكن',
            icon: Icons.location_on,
            destination: const LocationsPage(),
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
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
