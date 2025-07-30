import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:FireWatch/manager/managerTasks/reassignManager.dart';
import 'dart:ui' as ui;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> upcomingTasks = [];

  @override
  void initState() {
    super.initState();
    _loadUpcomingTasks();
  }

  Future<void> _loadUpcomingTasks() async {
    final now = DateTime.now();
    final twoDaysLater = now.add(const Duration(days: 2));
    print('🚀 Loading Manager Upcoming Tasks...');
    print('📅 Now: $now | 2 days later: $twoDaysLater');

    // ✅ Periodic tasks due soon
    final periodic = await supabase
        .from('periodic_tasks')
        .select('''
        id,
        assigned_at,
        assigned_to,
        completed,
        tool_id (
          name,
          next_maintenance_date
        ),
        users!assigned_to (
          name
        )
      ''')
        .eq('completed', false)
        .not('assigned_to', 'is', null)
        .gte('tool_id.next_maintenance_date', now.toIso8601String())
        .lte('tool_id.next_maintenance_date', twoDaysLater.toIso8601String());

    final List<Map<String, dynamic>> formattedPeriodic =
        periodic
            .map(
              (e) => {
                'id': e['id'],
                'tool': e['tool_id'],
                'technician': e['users'],
                'type': 'دوري',
                'time': e['tool_id']?['next_maintenance_date'],
              },
            )
            .where((e) => e['tool'] != null && e['technician'] != null)
            .toList();

    // ✅ Unapproved corrective/emergency
    final List<Map<String, dynamic>> unapproved = [];

    Future<void> fetchUnapprovedReports(String table) async {
      final response = await supabase
          .from(table)
          .select('''
          id,
          task_type,
          task_id,
          tool_name,
          technician_name,
          head_approved
        ''')
          .or('head_approved.eq.false,head_approved.is.null');

      for (final report in response) {
        if (report['tool_name'] != null && report['technician_name'] != null) {
          unapproved.add({
            'id': report['task_id'],
            'tool': {'name': report['tool_name']},
            'technician': {'name': report['technician_name']},
            'type': report['task_type'],
            'time': null,
          });
        }
      }
    }

    await fetchUnapprovedReports('fire_extinguisher_correctiveemergency');
    await fetchUnapprovedReports('fire_hydrant_reports');
    await fetchUnapprovedReports('hose_reel_reports');

    setState(() {
      upcomingTasks = [...formattedPeriodic, ...unapproved];
      isLoading = false;
    });

    print('✅ Total upcoming manager tasks: ${upcomingTasks.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text(
              'لوحة الإشعارات',
              style: TextStyle(color: Colors.white),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : upcomingTasks.isEmpty
                ? const Center(child: Text('لا توجد مهام تنتهي خلال يومين'))
                : ListView.builder(
                  itemCount: upcomingTasks.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final item = upcomingTasks[index];
                    final tool = item['tool'];
                    final technician = item['technician'];
                    final rawTime = item['time'];
                    final parsedDate =
                        rawTime != null ? DateTime.tryParse(rawTime) : null;
                    final dateText =
                        parsedDate != null
                            ? DateFormat('dd-MM-yyyy').format(parsedDate)
                            : 'غير معروف';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('الأداة: ${tool['name']}'),
                        subtitle: Text(
                          'النوع: ${item['type']} | الفني: ${technician['name']} | تاريخ الصيانة القادمة: $dateText',
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ToolReassignPage(taskId: item['id']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
