import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class ApprovedCorrectiveTasksPage extends StatefulWidget {
  const ApprovedCorrectiveTasksPage({super.key});

  @override
  State<ApprovedCorrectiveTasksPage> createState() =>
      _ApprovedCorrectiveTasksPageState();
}

class _ApprovedCorrectiveTasksPageState
    extends State<ApprovedCorrectiveTasksPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovedCorrectiveTasks();
  }

  Future<void> _loadApprovedCorrectiveTasks() async {
    final response = await supabase
        .from('corrective_tasks')
        .select('''
        id,
        status,
   
        tool_id (
          name
        ),
        report_id (
          tool_code,
          covered_area,
          usage_reason,
          action_taken,
          created_by_role,
          created_at,
          is_approved
        )
      ''')
        .order('assigned_at', ascending: false);

    debugPrint("📦 Raw response: $response");

    if (response.isEmpty) {
      debugPrint("⚠️ No tasks returned from Supabase.");
    }

    final filtered =
        response.where((task) {
          final report = task['report_id'];
          if (report == null) {
            return false;
          }
          if (report['is_approved'] != true) {
            return false;
          }
          return true;
        }).toList();

    debugPrint("✅ Filtered ${filtered.length} approved corrective tasks");

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
            'التقارير العملية - المهام العلاجية المعتمدة',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                ? const Center(child: Text('لا توجد مهام علاجية معتمدة'))
                : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final request = task['report_id'];

                    final tool = task['tool_id'];
                    final createdAt = DateTime.tryParse(
                      request['created_at'] ?? '',
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(
                          'اسم الأداة: ${tool['name'] ?? 'غير معروف'}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('السبب: ${request['usage_reason']}'),
                            Text('الإجراء المتخذ: ${request['action_taken']}'),
                            Text('الحالة: ${task['status'] ?? 'غير معروف'}'),
                            if (createdAt != null)
                              Text(
                                'التاريخ: ${DateFormat.yMd().add_Hm().format(createdAt)}',
                              ),
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
