import 'package:flutter/material.dart';
import 'package:FireWatch/technician/techNotifications.dart';
import 'package:FireWatch/technician/TechnichanCorrective.dart';
import 'package:FireWatch/technician/TechnichanEmergency.dart';
import 'package:FireWatch/technician/addTechReports/addEmergency.dart';
import 'package:FireWatch/technician/addTechReports/addCorrective.dart';
import 'package:FireWatch/technician/TechnichanPeriodic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TechnicianDashboardPage extends StatelessWidget {
  static const String routeName = 'technicianTasksMainPage';

  const TechnicianDashboardPage({super.key});

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
                      builder: (context) => AddEmergencyTaskTechnicianPage(),
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
                      builder: (context) => AddCorrectiveTaskTechnicianPage(),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text('لوحة مهام   ', style: TextStyle(color: Colors.white)),
          ),
          actions: [
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
                    builder: (context) => const TechnicianNotificationsPage(),
                  ),
                );
              },
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        title: const Text('تأكيد تسجيل الخروج'),
                        content: const Text(
                          'سيتم تسجيل خروجك من الحساب. هل أنت متأكد؟',
                        ),
                        actions: [
                              TextButton(
                            onPressed: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) {
                                Navigator.pop(context); 
                                Navigator.pop(
                                  context,
                                ); 
                              }
                            },
                            child: const Text('نعم'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('لا'),
                          ),
                      
                        ],
                      ),
                    ),
              );
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
          children: [
            _buildTile(
              context,
              title: 'دوري',
              icon: Icons.access_time,
              destinationPage: const TechnicianPeriodicLocationsPage(),
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              title: 'علاجي',
              icon: Icons.healing,
              destinationPage: const TechnicianCorrectiveLocationsPage(),
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              title: 'طارئ',
              icon: Icons.report,
              destinationPage: const TechnicianEmergencyLocationsPage(),
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
