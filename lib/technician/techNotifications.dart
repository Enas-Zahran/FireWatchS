import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/technician/TechnichanEmergency.dart';
import 'package:FireWatch/technician/TechnichanPeriodic.dart';
import 'package:FireWatch/technician/TechnichanCorrective.dart';

class TechnicianNotificationsPage extends StatefulWidget {
  const TechnicianNotificationsPage({super.key});

  @override
  State<TechnicianNotificationsPage> createState() =>
      _TechnicianNotificationsPageState();
}

class _TechnicianNotificationsPageState
    extends State<TechnicianNotificationsPage> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssignedTasks();
  }

  Future<void> _fetchAssignedTasks() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _tasks = [];
          _loading = false;
          _errorMessage = 'لم يتم تسجيل الدخول!';
        });
        return;
      }

      // Get دوري (periodic) tasks
      final periodic = await Supabase.instance.client
          .from('periodic_tasks')
          .select(
            'id, due_date, completed, tool_id, assigned_to, safety_tools(name)',
          )
          .eq('assigned_to', user.id)
          .order('due_date');

      // Get علاجي (corrective) tasks
      final corrective = await Supabase.instance.client
          .from('corrective_tasks')
          .select(
            'id, assigned_at, completed, tool_id, assigned_to, safety_tools(name)',
          )
          .eq('assigned_to', user.id)
          .order('assigned_at');

      // Get طارئ (emergency) tasks
      final emergency = await Supabase.instance.client
          .from('emergency_tasks')
          .select(
            'id, assigned_at, completed, tool_id, assigned_to, safety_tools(name)',
          )
          .eq('assigned_to', user.id)
          .order('assigned_at');

      // Merge all with type
      List<Map<String, dynamic>> all = [];
      all.addAll(
        List<Map<String, dynamic>>.from(
          periodic,
        ).map((t) => {...t, 'task_type': 'دوري'}),
      );
      all.addAll(
        List<Map<String, dynamic>>.from(
          corrective,
        ).map((t) => {...t, 'task_type': 'علاجي'}),
      );
      all.addAll(
        List<Map<String, dynamic>>.from(
          emergency,
        ).map((t) => {...t, 'task_type': 'طارئ'}),
      );

      // Mark overdue
      final today = DateTime.now();
      for (var task in all) {
        DateTime? assignedDate;
        if (task['task_type'] == 'دوري') {
          assignedDate = DateTime.tryParse(task['due_date'] ?? '');
        } else {
          assignedDate = DateTime.tryParse(task['assigned_at'] ?? '');
        }

        if (assignedDate != null) {
          final diff = today.difference(assignedDate).inDays;
          task['is_overdue'] = (!task['completed'] && diff > 5);
        } else {
          task['is_overdue'] = false;
        }
      }

      setState(() {
        _tasks = all;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      print('🔥 ERROR: $e');
      print('📍 STACKTRACE: $stackTrace');
      setState(() {
        _loading = false;
        _errorMessage = 'حدث خطأ أثناء جلب المهام: $e';
      });
    }
  }

  void _openTaskReport(Map<String, dynamic> task) {
    String type = task['task_type'] ?? '';
    if (type == 'دوري') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianPeriodicLocationsPage(),
        ),
      );
    } else if (type == 'علاجي') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianCorrectiveLocationsPage(),
        ),
      );
    } else if (type == 'طارئ') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianEmergencyLocationsPage(),
        ),
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
            child: Text(
              'إشعارات المهام الجديدة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                )
                : _tasks.isEmpty
                ? const Center(
                  child: Text(
                    'لا يوجد مهام جديدة حاليًا',
                    style: TextStyle(fontSize: 20),
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView.separated(
                    itemCount: _tasks.length,
                    separatorBuilder:
                        (context, i) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final task = _tasks[i];
                      final toolName = task['safety_tools']?['name'] ?? '---';
                      String date = '';
                      if (task['task_type'] == 'دوري') {
                        date = task['due_date'] ?? '';
                      } else {
                        date = task['assigned_at'] ?? '';
                      }

                      return Card(
                        color:
                            task['is_overdue'] == true ? Colors.red[100] : null,
                        child: ListTile(
                          title: Text(
                            '$toolName (${task['task_type']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('تاريخ الإسناد/الصيانة: $date'),
                              if (task['is_overdue'] == true)
                                const Text(
                                  '⚠️ مضى أكثر من 5 أيام ولم يتم تنفيذ المهمة!',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _openTaskReport(task),
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
