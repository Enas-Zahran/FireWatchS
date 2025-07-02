import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/technician/TechnichanCorrective/fireextinguisherTwo.dart';
import 'package:FireWatch/technician/General/firehydrantsReport.dart';
import 'package:FireWatch/technician/General/hosereelReport.dart';

class TechnicianEmergencyLocationsPage extends StatefulWidget {
  static const routeName = 'emergencyTasksPage';
  const TechnicianEmergencyLocationsPage({super.key});

  @override
  State<TechnicianEmergencyLocationsPage> createState() => _TechnicianEmergencyLocationsPageState();
}

class _TechnicianEmergencyLocationsPageState extends State<TechnicianEmergencyLocationsPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _toolSearchController = TextEditingController();

  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> locations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await _fetchLocations();
      await _fetchRequests();
    } catch (e) {
      _showErrorSnackbar('فشل في تحميل البيانات: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLocations() async {
    final response = await supabase.from('locations').select('id, name, code');
    locations = List<Map<String, dynamic>>.from(response);
  }

  Future<void> _fetchRequests() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('emergency_tasks')
        .select('id, status, tool_id, safety_tools(id, name, type)')
        .eq('assigned_to', user.id);

    requests = [];
    for (final task in response) {
      final tool = task['safety_tools'];
      if (tool != null) {
        requests.add({
          'task_id': task['id'],
          'status': task['status'],
          'tool_name': tool['name'],
          'tool_type': tool['type'],
        });
      }
    }
  }

  List<Map<String, dynamic>> _tasksForPlace(String code) {
    return requests.where((task) {
      final name = task['tool_name'] ?? '';
      return name.isNotEmpty && name[0].toUpperCase() == code.toUpperCase();
    }).toList();
  }

  void _navigateToReport(
    BuildContext context,
    Map<String, dynamic> task,
  ) async {
    final type = task['tool_type']?.toString().toLowerCase();
    final taskId = task['task_id'];
    final toolName = task['tool_name'];

    if (type == 'fire extinguisher') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FireExtinguisherCorrectiveEmergency(
                taskId: taskId,
                toolName: toolName,
                taskType: 'طارئ',
              ),
        ),
      );
    } else if (type == 'fire hydrant') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FireHydrantReportPage(
                taskId: taskId,
                toolName: toolName,
                taskType: 'طارئ',
              ),
        ),
      );
    } else if (type == 'hose reel') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => HoseReelReportPage(
                taskId: taskId,
                toolName: toolName,
                taskType: 'طارئ',
              ),
        ),
      );
    }

    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المواقع - المهام الطارئة',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body:
            _isLoading
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
                    final remainingTasks =
                        tasksInPlace.where((e) => e['status'] != 'done').length;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          '$name ($code) - $remainingTasks مهام',
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
                                  final isDone = task['status'] == 'done';
                                  return ListTile(
                                    title: Text(
                                      task['tool_name'] ?? '',
                                      style: TextStyle(
                                        color: isDone ? Colors.green : null,
                                        fontWeight:
                                            isDone ? FontWeight.bold : null,
                                      ),
                                    ),
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
