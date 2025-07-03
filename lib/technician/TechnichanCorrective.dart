import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/technician/TechnichanCorrective/fireextinguisherTwo.dart';
import 'package:FireWatch/technician/General/firehydrantsReport.dart';
import 'package:FireWatch/technician/General/hosereelReport.dart';

class TechnicianCorrectiveLocationsPage extends StatefulWidget {
  const TechnicianCorrectiveLocationsPage({super.key});

  @override
  State<TechnicianCorrectiveLocationsPage> createState() => _TechnicianCorrectiveLocationsPageState();
}

class _TechnicianCorrectiveLocationsPageState extends State<TechnicianCorrectiveLocationsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> assignedTasks = [];
  String? userId;
  bool showCompleted = false;

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

    final userInfo = await Supabase.instance.client.from('users').select('name').eq('id', id).maybeSingle();
    final technicianName = userInfo?['name'] ?? 'Unknown';

    final locs = await Supabase.instance.client.from('locations').select('id, name, code');

    final tasksResult = await Supabase.instance.client
        .from('corrective_tasks')
        .select('id, tool_id, status, assigned_to, safety_tools(id, name, type)')
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
          'status': t['status'],
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
      final match = name.isNotEmpty && name[0].toUpperCase() == code.toUpperCase();
      final isDone = task['status'] == 'done';
      return match && (showCompleted || !isDone);
    }).toList();
  }

  void _navigateToReport(BuildContext context, Map<String, dynamic> task) async {
    final type = task['tool_type']?.toString().toLowerCase();
    final taskId = task['task_id'];
    final toolName = task['tool_name'];
    final technicianName = task['technician_name'];
    final isDone = task['status'] == 'done';

    if (type == 'fire extinguisher') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FireExtinguisherCorrectiveEmergency(
            taskId: taskId,
            toolName: toolName,
            taskType: 'علاجي',
            isReadonly: isDone,
          ),
        ),
      );
    } else if (type == 'fire hydrant') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FireHydrantReportPage(
            taskId: taskId,
            toolName: toolName,
            taskType: 'علاجي',
            isReadonly: isDone,
          ),
        ),
      );
    } else if (type == 'hose reel') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HoseReelReportPage(
            taskId: taskId,
            toolName: toolName,
            taskType: 'علاجي',
            isReadonly: isDone,
          ),
        ),
      );
    }

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المواقع - المهام العلاجية', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Row(
              children: [
                const Text('عرض المكتملة', style: TextStyle(color: Colors.white)),
                Switch(
                  value: showCompleted,
                  onChanged: (val) => setState(() => showCompleted = val),
                ),
              ],
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final loc = locations[index];
                  final code = loc['code'] ?? '';
                  final name = loc['name'] ?? '';
                  final tasksInPlace = _tasksForPlace(code);
                  final remainingTasks = tasksInPlace.where((e) => e['status'] != 'done').length;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ExpansionTile(
                      title: Text(
                        '$name ($code) - $remainingTasks مهام',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: tasksInPlace.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('لا يوجد مهام مسندة لهذا المكان'),
                              )
                            ]
                          : tasksInPlace.map((task) {
                              final isDone = task['status'] == 'done';
                              return ListTile(
                                title: Text(
                                  task['tool_name'] ?? '',
                                  style: TextStyle(
                                    color: isDone ? Colors.green : null,
                                    fontWeight: isDone ? FontWeight.bold : null,
                                  ),
                                ),
                                subtitle: Text(task['tool_type'] ?? ''),
                                onTap: () => _navigateToReport(context, task),
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
