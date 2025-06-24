import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/manager/managerTasks/reassignManager.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _pendingTasks = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingTasks();
  }

  Future<void> _fetchPendingTasks() async {
    try {
      final today = DateTime.now();
      final targetDate = today.add(const Duration(days: 2));
      
      final dueDateStr = targetDate.toIso8601String().substring(0, 10);

      print('Fetching tasks with due_date = $dueDateStr');
      final data = await Supabase.instance.client
          .from('periodic_tasks')
          .select('id, assigned_at, due_date, completed, assigned_to, tool_id, safety_tools(name)')
          .eq('completed', false)
          .eq('due_date', dueDateStr);

      print('Query result: $data');

      setState(() {
        _pendingTasks = List<Map<String, dynamic>>.from(data);
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _loading = false;
        _errorMessage = 'حدث خطأ أثناء جلب المهام.';
      });
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
            child: Text('لوحة الاشعارات', style: TextStyle(color: Colors.white)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
           
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 18)))
                : _pendingTasks.isEmpty
                    ? const Center(child: Text('لا يوجد مهام خلال اليومين القادمين', style: TextStyle(fontSize: 20)))
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: const Text(
                                'بقي يومين لاتمام هذه المهام',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _pendingTasks.length,
                                separatorBuilder: (context, i) => const SizedBox(height: 14),
                                itemBuilder: (context, i) {
                                  final task = _pendingTasks[i];
                                  final toolName = task['safety_tools']?['name'] ?? '---';
                                  final dueDate = task['due_date'] ?? '';
                                  return Card(
                                    child: ListTile(
                                      title: Text(toolName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('تاريخ الصيانة القادمة: $dueDate'),
                                      trailing: const Icon(Icons.arrow_forward_ios),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ToolReassignPage(taskId: task['id']),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
