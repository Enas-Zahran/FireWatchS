import 'package:flutter/material.dart';
import 'package:FireWatch/technician/techNotifications.dart';
import 'package:FireWatch/technician/TechnichanCorrective.dart';
import 'package:FireWatch/technician/TechnichanEmergency.dart';
import 'package:FireWatch/technician/addTechReports/addEmergency.dart';
import 'package:FireWatch/technician/addTechReports/addCorrective.dart';
import 'package:FireWatch/technician/TechnichanPeriodic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/technician/MaterialExit.dart';
import 'package:FireWatch/technician/ApprovedList.dart';

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

  Future<int> getNotificationCount(String technicianId) async {
    final supabase = Supabase.instance.client;

    final periodic = await supabase
        .from('periodic_tasks')
        .select()
        .eq('assigned_to', technicianId)
        .neq('status', 'done');

    final corrective = await supabase
        .from('corrective_tasks')
        .select()
        .eq('assigned_to', technicianId)
        .neq('status', 'done');

    final emergency = await supabase
        .from('emergency_tasks')
        .select()
        .eq('assigned_to', technicianId)
        .neq('status', 'done');

    return periodic.length + corrective.length + emergency.length;
  }

  void _navigateToApprovedRequests(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final userId = user.id;
      final userName = user.userMetadata?['name'] ?? '---';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => TechnicianApprovedRequestsPage(
                technicianId: userId,
                technicianName: userName,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ: لم يتم العثور على المستخدم')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text('لوحة مهام', style: TextStyle(color: Colors.white)),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'اضافة تقرير',
              onPressed: () => _showAddOptions(context),
            ),
            StatefulBuilder(
              builder: (context, setState) {
                return FutureBuilder<int>(
                  future: getNotificationCount(
                    Supabase.instance.client.auth.currentUser!.id,
                  ),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                          tooltip: 'الإشعارات',
                          onPressed: () async {
                            // Navigate and wait for return
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const TechnicianNotificationsPage(),
                              ),
                            );
                            // 🔁 Refresh when returned
                            setState(() {});
                          },
                        ),
                        if (count > 0)
                          const Positioned(
                            top: 12,
                            right: 12,
                            child: CircleAvatar(
                              radius: 5,
                              backgroundColor: Colors.red,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),

            IconButton(
              icon: const Icon(Icons.file_upload, color: Colors.white),
              tooltip: 'تصريح إخراج المواد',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaterialExitAuthorizationPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.assignment_turned_in, color: Colors.white),
              tooltip: 'تصاريح الإخراج المعتمدة',
              onPressed: () => _navigateToApprovedRequests(context),
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
                                Navigator.pop(context); // close dialog
                                Navigator.pop(context); // go back to login
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
