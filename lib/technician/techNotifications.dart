import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TechnicianNotificationsPage extends StatefulWidget {
  const TechnicianNotificationsPage({super.key});

  @override
  State<TechnicianNotificationsPage> createState() =>
      _TechnicianNotificationsPageState();
}

class _TechnicianNotificationsPageState
    extends State<TechnicianNotificationsPage> {
  final supabase = Supabase.instance.client;
  String technicianId = Supabase.instance.client.auth.currentUser!.id;
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllAssignedTasks();
  }

  Future<void> _loadAllAssignedTasks() async {
    final periodic = await supabase
        .from('periodic_tasks')
        .select('id, status, tool_id (name)')
        .eq('assigned_to', technicianId)
        .neq('status', 'done');

    final corrective = await supabase
        .from('corrective_tasks')
        .select('id, status, tool_id (name)')
        .eq('assigned_to', technicianId)
        .neq('status', 'done');

    final emergency = await supabase
        .from('emergency_tasks')
        .select('id, status, tool_id (name)')
        .eq('assigned_to', technicianId)
        .neq('status', 'done');

    final combined = [
      ...periodic
          .where((e) => e['tool_id'] != null)
          .map(
            (e) => {
              'id': e['id'],
              'status': e['status'],
              'tool': e['tool_id']['name'],
              'type': 'دوري',
            },
          ),

      ...corrective.map(
        (e) => {
          'id': e['id'],
          'status': e['status'],
          'tool': e['tool_id']['name'],
          'type': 'علاجي',
        },
      ),
      ...emergency.map(
        (e) => {
          'id': e['id'],
          'status': e['status'],
          'tool': e['tool_id']['name'],
          'type': 'طارئ',
        },
      ),
    ];

    setState(() {
      tasks = combined;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: Center(
            child: const Text(
              'الإشعارات',
              style: TextStyle(color: Colors.white),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                ? const Center(child: Text('لا توجد مهام جديدة.'))
                : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Center(child: Text('الأداة: ${task['tool']}')),
                        subtitle: Center(
                          child: Text('النوع: ${task['type']} '),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
