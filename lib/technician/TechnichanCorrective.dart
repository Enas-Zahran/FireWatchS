import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/technician/General/firehydrantsReport.dart';
import 'package:FireWatch/technician/General/hosereelReport.dart';
import 'package:FireWatch/technician/TechnichanCorrective/fireextinguisherTwo.dart';

class TechnicianCorrectiveLocationsPage extends StatefulWidget {
  const TechnicianCorrectiveLocationsPage({super.key});

  @override
  State<TechnicianCorrectiveLocationsPage> createState() =>
      _TechnicianCorrectiveLocationsPageState();
}

class _TechnicianCorrectiveLocationsPageState
    extends State<TechnicianCorrectiveLocationsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> assignedTasks = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final user = Supabase.instance.client.auth.currentSession?.user;
    final id = user?.id;

    if (id == null) {
      setState(() => _loading = false);
      return;
    }

    final userInfo =
        await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', id)
            .maybeSingle();

    final technicianName = userInfo?['name'] ?? 'Unknown';

    final locs = await Supabase.instance.client
        .from('locations')
        .select('id, name, code');

    final tasksResult = await Supabase.instance.client
        .from('corrective_tasks')
        .select('id, tool_id, assigned_to, safety_tools(id, name, type)')
        .eq('assigned_to', id);

    List<Map<String, dynamic>> correctiveTasks = [];
    for (final t in tasksResult) {
      if (t['safety_tools'] != null) {
        correctiveTasks.add({
          'task_id': t['id'],
          'tool_id': t['tool_id'],
          'tool_name': t['safety_tools']['name'],
          'tool_type': t['safety_tools']['type'],
          'technician_name': technicianName,
        });
      }
    }

    setState(() {
      locations = List<Map<String, dynamic>>.from(locs);
      assignedTasks = correctiveTasks;
      userId = id;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _tasksForPlace(String code) {
    return assignedTasks.where((task) {
      final name = task['tool_name'] ?? '';
      return name.isNotEmpty && name[0].toUpperCase() == code.toUpperCase();
    }).toList();
  }

  void _navigateToReport(BuildContext context, Map<String, dynamic> task) {
    final type = task['tool_type']?.toString().toLowerCase();
    final taskId = task['task_id'];
    final toolName = task['tool_name'];
    final technicianName = task['technician_name'];

    if (type == 'fire extinguisher') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FireExtinguisherCorrectiveEmergency(
                taskId: taskId,
                toolName: toolName,
                taskType: 'علاجي',
              ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigate to Fire Extinguisher Corrective Report'),
        ),
      );
    } else if (type == 'fire hydrant') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  FireHydrantReportPage(taskId: taskId, toolName: toolName),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigate to Fire Hydrant Corrective Report'),
        ),
      );
    } else if (type == 'hose reel') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => HoseReelReportPage(
                taskId: task['task_id'], // ✅ fixed here
                toolName: task['tool_name'], // ✅ fixed here
                taskType: 'علاجي',
              ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigate to Hose Reel Corrective Report'),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('نوع الأداة غير معروف: $type')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المواقع - المهام العلاجية',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final loc = locations[index];
                    final code = loc['code'] ?? '';
                    final name = loc['name'] ?? '';
                    final tasksInPlace = _tasksForPlace(code);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          '$name ($code)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children:
                            tasksInPlace.isEmpty
                                ? [
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'لا يوجد مهام مسندة لهذا المكان',
                                    ),
                                  ),
                                ]
                                : tasksInPlace.map((task) {
                                  return ListTile(
                                    title: Text(task['tool_name'] ?? ''),
                                    subtitle: Text(task['tool_type'] ?? ''),
                                    onTap:
                                        () => _navigateToReport(context, task),
                                  );
                                }).toList(),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
