import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui'as ui;
class ApprovedEmergencyTasksPage extends StatefulWidget {
  const ApprovedEmergencyTasksPage({super.key});

  @override
  State<ApprovedEmergencyTasksPage> createState() => _ApprovedEmergencyTasksPageState();
}

class _ApprovedEmergencyTasksPageState extends State<ApprovedEmergencyTasksPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovedEmergencyTasks();
  }

  Future<void> _loadApprovedEmergencyTasks() async {
    final response = await supabase
        .from('emergency_tasks')
        .select('''
          id,
          status,
          created_at,
          tool_id (
            name
          ),
          request_id (
            tool_code,
            covered_area,
            usage_reason,
            action_taken,
            created_by_role,
            created_at,
            is_approved
          )
        ''')
        .order('created_at', ascending: false);

    final filtered = response.where((task) =>
        task['request_id'] != null &&
        task['request_id']['is_approved'] == true).toList();

    setState(() {
      tasks = List<Map<String, dynamic>>.from(filtered);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'التقارير العملية - المهام الطارئة المعتمدة',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : tasks.isEmpty
                ? const Center(child: Text('لا توجد مهام طارئة معتمدة'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final request = task['request_id'];
                      final tool = task['tool_id'];
                      final createdAt = DateTime.tryParse(request['created_at'] ?? '');

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('اسم الأداة: ${tool['name'] ?? 'غير معروف'}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('رمز الأداة: ${request['tool_code']}'),
                              Text('المساحة: ${request['covered_area']}'),
                              Text('السبب: ${request['usage_reason']}'),
                              Text('الإجراء المتخذ: ${request['action_taken']}'),
                              Text('الدور: ${request['created_by_role']}'),
                              Text('الحالة: ${task['status'] ?? 'غير معروف'}'),
                              if (createdAt != null)
                                Text('التاريخ: ${DateFormat.yMd().add_Hm().format(createdAt)}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
