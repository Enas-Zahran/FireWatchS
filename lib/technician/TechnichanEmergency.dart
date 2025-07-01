import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/technician/TechnichanCorrective/fireextinguisherTwo.dart';
import 'package:FireWatch/technician/General/firehydrantsReport.dart';
import 'package:FireWatch/technician/General/hosereelReport.dart';

class TechnicianEmergencyLocationsPage extends StatefulWidget {
  const TechnicianEmergencyLocationsPage({super.key});

  @override
  State<TechnicianEmergencyLocationsPage> createState() => _TechnicianEmergencyLocationsPageState();
}

class _TechnicianEmergencyLocationsPageState extends State<TechnicianEmergencyLocationsPage> {
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

    final userInfo = await Supabase.instance.client
        .from('users')
        .select('name')
        .eq('id', id)
        .maybeSingle();

    final technicianName = userInfo?['name'] ?? 'Unknown';

    final locs = await Supabase.instance.client.from('locations').select('id, name, code');

    final tasksResult = await Supabase.instance.client
        .from('emergency_tasks')
        .select('id, tool_id, assigned_to, safety_tools(id, name, type)')
        .eq('assigned_to', id);

    List<Map<String, dynamic>> emergencyTasks = [];
    for (final t in tasksResult) {
      if (t['safety_tools'] != null) {
        emergencyTasks.add({
          'task_id': t['id'],
          'tool_id': t['tool_id'],
          'tool_name': t['safety_tools']['name'],
          'tool_type': t['safety_tools']['type'],
        });
      }
    }

    setState(() {
      locations = List<Map<String, dynamic>>.from(locs);
      assignedTasks = emergencyTasks;
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

    if (type == 'fire extinguisher') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FireExtinguisherCorrectiveEmergency(
            taskId: taskId,
            toolName: toolName,
            taskType: 'طارئ',
          ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigate to Fire Extinguisher Emergency Report')),
      );
    } else if (type == 'fire hydrant') {
    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => FireHydrantReportPage(
      taskId: task['task_id'],         // ✅ ID الخاص بالمهمة
      toolName: task['tool_name'],     // ✅ اسم أداة السلامة
      taskType: 'طارئ',               // أو 'دوري' أو 'طارئ'
    ),
  ),
);

     
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigate to Fire Hydrant Emergency Report')),
      );
    } else if (type == 'hose reel') {
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => HoseReelReportPage(
      taskId: task['task_id'],        // ✅ fixed here
      toolName: task['tool_name'],    // ✅ fixed here
      taskType: 'طارئ',
    ),
  ),
);
   ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigate to Hose Reel Emergency Report')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('نوع الأداة غير معروف: $type')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المواقع - المهام الطارئة', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
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

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ExpansionTile(
                      title: Text('$name ($code)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      children: tasksInPlace.isEmpty
                          ? [
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('لا يوجد مهام مسندة لهذا المكان'),
                              )
                            ]
                          : tasksInPlace.map((task) {
                              return ListTile(
                                title: Text(task['tool_name'] ?? ''),
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
