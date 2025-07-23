import 'package:flutter/material.dart';
import 'package:FireWatch/head/HeadPeriodicLocation.dart';
import 'package:FireWatch/head/HeadCorrectiveLocation.dart';
import 'package:FireWatch/head/HeadEmergencyLocation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/head/HeadNotifications.dart';
import 'package:FireWatch/My/BuildTile.dart';

class Headdashboard extends StatefulWidget {
  static const String routeName = 'headTasksMainPage';

  const Headdashboard({super.key});

  @override
  State<Headdashboard> createState() => _HeaddashboardState();
}

class _HeaddashboardState extends State<Headdashboard> {
  final supabase = Supabase.instance.client;
  bool hasNotifications = false;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));

    print('🚀 Checking notifications for head...');
    print('📅 Now: $now - 3 days later: $threeDaysLater');

    final periodic = await supabase
        .from('periodic_tasks')
        .select('id, tool_id (next_maintenance_date)')
        .neq('status', 'done')
        .not('assigned_to', 'is', null)
        .gte('tool_id.next_maintenance_date', now.toIso8601String())
        .lte('tool_id.next_maintenance_date', threeDaysLater.toIso8601String());

    final corrective = await supabase
        .from('corrective_tasks')
        .select('id')
        .neq('status', 'done')
        .not('assigned_to', 'is', null);

    final emergency = await supabase
        .from('emergency_tasks')
        .select('id')
        .neq('status', 'done')
        .not('assigned_to', 'is', null);

    final total = periodic.length + corrective.length + emergency.length;

    print('🔍 periodic = ${periodic.length}');
    print('🔍 corrective = ${corrective.length}');
    print('🔍 emergency = ${emergency.length}');
    print('🔔 Total notifications = $total');

    setState(() {
      hasNotifications = total > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text(
              'لوحة رئيس الشعبة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  tooltip: 'الإشعارات',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HeadNotificationsPage(),
                      ),
                    );
                    _checkNotifications(); // Refresh after return
                  },
                ),
                if (hasNotifications)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
          children: const [
            BuildTile(
              title: 'دوري',
              icon: Icons.access_time,
              destination: HeadPeriodicLocationsPage(),
            ),
            SizedBox(height: 12),
            BuildTile(
              title: 'علاجي',
              icon: Icons.healing,
              destination: HeadCorrectiveLocationsPage(),
            ),
            SizedBox(height: 12),
            BuildTile(
              title: 'طارئ',
              icon: Icons.report,
              destination: HeadEmergencyLocationsPage(),
            ),
          ],
        ),
      ),
    );
  }
}
