import 'package:flutter/material.dart';
// Import your forms/pages here for reports/updates
import 'package:FireWatch/technician/TechnichanEmergency.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/technician/TechnichanPeriodic.dart';
import 'package:FireWatch/technician/TechnichanCorrective.dart';

class TechnicianNotificationsPage extends StatefulWidget {
  const TechnicianNotificationsPage({super.key});

  @override
  State<TechnicianNotificationsPage> createState() => _TechnicianNotificationsPageState();
}

class _TechnicianNotificationsPageState extends State<TechnicianNotificationsPage> {
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
          .select('id, due_date, completed, tool_id, safety_tools(name), assigned_to')
          .eq('assigned_to', user.id)
          .order('due_date');

      // Get علاجي (corrective) tasks
      final corrective = await Supabase.instance.client
          .from('corrective_tasks')
          .select('id, assigned_at, completed, tool_id, safety_tools(name), assigned_to')
          .eq('assigned_to', user.id)
          .order('assigned_at');

      // Get طارئ (emergency) tasks
      final emergency = await Supabase.instance.client
          .from('emergency_tasks')
          .select('id, assigned_at, completed, tool_id, safety_tools(name), assigned_to')
          .eq('assigned_to', user.id)
          .order('assigned_at');

      // Tag each task with its type so we know where to send the technician
      List<Map<String, dynamic>> all = [];
      all.addAll(List<Map<String, dynamic>>.from(periodic).map((t) => {...t, 'task_type': 'دوري'}));
      all.addAll(List<Map<String, dynamic>>.from(corrective).map((t) => {...t, 'task_type': 'علاجي'}));
      all.addAll(List<Map<String, dynamic>>.from(emergency).map((t) => {...t, 'task_type': 'طارئ'}));

      // You can also filter to show only incomplete tasks, or add a "new" flag, etc.

      setState(() {
        _tasks = all;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'حدث خطأ أثناء جلب المهام.';
      });
    }
  }

  void _openTaskReport(Map<String, dynamic> task) {
    String type = task['task_type'] ?? '';
    if (type == 'دوري') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>TechnicianPeriodicLocationsPage ()),
        
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
            child: Text('إشعارات المهام الجديدة', style: TextStyle(color: Colors.white)),
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
                : _tasks.isEmpty
                    ? const Center(child: Text('لا يوجد مهام جديدة حاليًا', style: TextStyle(fontSize: 20)))
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: ListView.separated(
                          itemCount: _tasks.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 14),
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
                              child: ListTile(
                                title: Text('$toolName (${task['task_type']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('تاريخ الإسناد/الصيانة: $date'),
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
