import 'package:flutter/material.dart';
import 'package:FireWatch/My/BuildTile.dart';
import 'package:FireWatch/manager/managerAddEdit/UsersManger/usersManager.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/equipmentManager.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/pricesManager.dart';
import 'package:FireWatch/manager/managerAddEdit/LocationManger/locationManger.dart';

class AddEditPage extends StatelessWidget {
  static const String addEditDashboardRoute = 'addeditdashboard';

  const AddEditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
            BuildTile( title: 'المستخدمين', icon: Icons.person, destination: ManagerUserListPage()),
            const SizedBox(height: 12),
            BuildTile( title: 'المعدات', icon: Icons.build, destination: AllToolsPage()),
            const SizedBox(height: 12),
            BuildTile( title: 'الأسعار', icon: Icons.attach_money, destination: PriceDashboardPage()),
            const SizedBox(height: 12),
            BuildTile( title: 'الأماكن', icon: Icons.location_on, destination: const LocationsPage()),
          ],
        ),
      ),
    );
  }
}

