import 'package:flutter/material.dart';
import 'package:FireWatch/manager/managerTasks/addManagerReports/addEmergency.dart';
import 'package:FireWatch/manager/managerTasks/addManagerReports/addCorrective.dart';
import 'package:FireWatch/manager/managerTasks/approvalTasks.dart';
import 'package:FireWatch/manager/managerTasks/periodicManager.dart';
import 'package:FireWatch/manager/managerTasks/correctiveManager.dart';
import 'package:FireWatch/manager/managerTasks/emergencyManager.dart';
import 'package:FireWatch/manager/managerTasks/notificationsManager.dart';
import 'package:FireWatch/My/BuildTile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TasksMainPage extends StatefulWidget {
  const TasksMainPage({super.key});

  @override
  State<TasksMainPage> createState() => _TasksMainPageState();
}

class _TasksMainPageState extends State<TasksMainPage> {
  bool _hasPendingRequests = false;

  @override
  void initState() {
    super.initState();
    _checkPendingRequests();
  }

  Future<void> _checkPendingRequests() async {
    final data = await Supabase.instance.client
        .from('emergency_requests')
        .select('id')
        .eq('is_approved', false)
        .neq('created_by_role', 'المدير')
        .limit(1);

    setState(() {
      _hasPendingRequests = data.isNotEmpty;
    });
  }

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text('لوحة المهام', style: TextStyle(color: Colors.white)),
          ),
          actions: [
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.mail, color: Colors.white),
                  if (_hasPendingRequests)
                    const Positioned(
                      top: -4,
                      right: -4,
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Color(0xffae2f34),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PendingEmergencyRequestsPage(),
                  ),
                );
                _checkPendingRequests(); // يعيد التحقق بعد العودة
              },
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
            BuildTile(
              title: 'دوري',
              icon: Icons.access_time,
              destination: const PeriodicTasksPage(),
            ),
            const SizedBox(height: 12),
            BuildTile(
              title: 'علاجي',
              icon: Icons.healing,
              destination: CorrectiveTasksPage(),
            ),
            const SizedBox(height: 12),
            BuildTile(
              title: 'طارئ',
              icon: Icons.report,
              destination: EmergencyTasksPage(),
            ),
          ],
        ),
      ),
    );
  }
}
