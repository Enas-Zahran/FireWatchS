import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

class HeadNotificationsPage extends StatefulWidget {
  const HeadNotificationsPage({super.key});

  @override
  State<HeadNotificationsPage> createState() => _HeadNotificationsPageState();
}

class _HeadNotificationsPageState extends State<HeadNotificationsPage> {
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
    final threeDaysLater = now.add(const Duration(days: 3));

    print('🚀 Starting _loadUpcomingTasks... ');
    print('📅 Now: $now | 3 days later: $threeDaysLater');

    // 🟦 Periodic Tasks
    final periodic = await supabase
        .from('periodic_tasks')
        .select('''
        id,
        status,
        assigned_to,
        tool_id (
          name,
          next_maintenance_date
        ),
        users!assigned_to (
          name
        )
      ''')
        .neq('status', 'done')
        .not('assigned_to', 'is', null)
     
        .gte('tool_id.next_maintenance_date', now.toIso8601String())
        .lte('tool_id.next_maintenance_date', threeDaysLater.toIso8601String());

    print('🟦 periodic length = ${periodic.length}');

    // 🟨 Corrective Tasks (no date filter!)
    final corrective = await supabase
        .from('corrective_tasks')
        .select('''
        id,
        status,
        assigned_to,
        assigned_at,
        tool_id (
          name
        ),
        users!assigned_to (
          name
        )
      ''')
        .neq('status', 'done')
        
        .not('assigned_to', 'is', null);

    print('🟨 corrective length = ${corrective.length}');

    // 🟥 Emergency Tasks (no date filter!)
    final emergency = await supabase
        .from('emergency_tasks')
        .select('''
        id,
        status,
        assigned_to,
        assigned_at,
        tool_id (
          name
        ),
        users!assigned_to (
          name
        )
      ''')
     
        .neq('status', 'done')
        .not('assigned_to', 'is', null);

    print('🟥 emergency length = ${emergency.length}');

    // Combine all
    final all = [
      ...periodic.map(
        (e) => {
          'tool': e['tool_id'],
          'technician': e['users'],
          'type': 'دوري',
          'time': e['tool_id']?['next_maintenance_date'],
        },
      ),
      ...corrective.map(
        (e) => {
          'tool': e['tool_id'],
          'technician': e['users'],
          'type': 'علاجي',
          'time': e['assigned_at'],
        },
      ),
      ...emergency.map(
        (e) => {
          'tool': e['tool_id'],
          'technician': e['users'],
          'type': 'طارئ',
          'time': e['assigned_at'],
        },
      ),
    ];

    setState(() {
      upcomingTasks =
          all
              .where(
                (item) => item['tool'] != null && item['technician'] != null,
              )
              .toList();
      isLoading = false;
    });

    print('🧮 Total tasks: ${upcomingTasks.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: Center(
            child: const Text(
              'إشعارات المهام القريبة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : upcomingTasks.isEmpty
                ? const Center(child: Text('لا توجد مهام تنتهي خلال ٣ أيام'))
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
                          'النوع: ${item['type']} | الفني: ${technician['name']} | تم الإسناد في: $dateText',
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
