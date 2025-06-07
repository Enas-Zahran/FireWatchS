import 'package:flutter/material.dart';
import 'priority/dawry_page.dart';
import 'priority/elaji_page.dart';
import 'priority/taree_page.dart';
import 'package:FireWatch/All/addemergency.dart';

//Todo notifications icon
class TechnicianDashboard extends StatelessWidget {
  static const String techniciandashboardRoute = 'techniciandashboard';

  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff00408b),
        title: Center(
          child: const Text(
            'لوحة تحكم الفني',
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
                    title: Text('تأكيد'),
                    content: Text('هل أنت متأكد من الرجوع لصفحة الدخول؟'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('إلغاء'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                      ),
                      TextButton(
                        child: Text('نعم'),
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog first
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          ); 
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notifications here
            },
          ),
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
            destination: TechnicianDawriPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'علاجي',
            icon: Icons.medical_services,
            destination: TechnicianElajiPage(),
          ),
          const SizedBox(height: 12),
          _buildTile(
            context,
            title: 'طارئ',
            icon: Icons.warning,
            destination: TechnicianEmergencyPage(),
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
