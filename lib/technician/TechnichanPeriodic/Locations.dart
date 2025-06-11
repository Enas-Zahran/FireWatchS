import 'package:FireWatch/technician/TechnichanPeriodic/firehydrantsPeriodic.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your report pages here
// import 'package:FireWatch/technician/reports/FireExtinguisherReportPage.dart';
// import 'package:FireWatch/technician/reports/FireHydrantReportPage.dart';
// import 'package:FireWatch/technician/reports/HoseReelReportPage.dart';
import 'package:FireWatch/technician/TechnichanPeriodic/fireextinguisherPeridoic.dart';

class TechnicianPeriodicLocationsPage extends StatefulWidget {
  const TechnicianPeriodicLocationsPage({super.key});

  @override
  State<TechnicianPeriodicLocationsPage> createState() =>
      _TechnicianPeriodicLocationsPageState();
}

class _TechnicianPeriodicLocationsPageState
    extends State<TechnicianPeriodicLocationsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> assignedTools = [];
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

    // 1. Fetch locations
    final locs = await Supabase.instance.client
        .from('locations')
        .select('id, name, code');
    // 2. Fetch periodic_tasks assigned to this technician, joined with tool info (include type)
    final toolsResult = await Supabase.instance.client
        .from('periodic_tasks')
        .select('id, tool_id, assigned_to, safety_tools(id, name, type)')
        .eq('assigned_to', id);

    List<Map<String, dynamic>> periodicTools = [];
    for (final t in toolsResult) {
      if (t['safety_tools'] != null) {
        periodicTools.add({
          'task_id': t['id'],
          'tool_id': t['tool_id'],
          'tool_name': t['safety_tools']['name'],
          'tool_type': t['safety_tools']['type'],
        });
      }
    }

    setState(() {
      locations = List<Map<String, dynamic>>.from(locs);
      assignedTools = periodicTools;
      userId = id;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _toolsForPlace(String code) {
    return assignedTools.where((tool) {
      final name = tool['tool_name'] ?? '';
      return name.isNotEmpty && name[0].toUpperCase() == code.toUpperCase();
    }).toList();
  }

  // Helper: navigate to appropriate report page based on type
  void _navigateToReport(BuildContext context, Map<String, dynamic> tool) {
    final type = tool['tool_type']?.toString().toLowerCase();
    final taskId = tool['task_id'];
    final toolName = tool['tool_name'];

    if (type == 'fire extinguisher') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FireExtinguisherReportPage(
                taskId: taskId,
                toolName: toolName,
              ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigate to Fire Extinguisher Report')),
      );
    } else if (type == 'fire hydrant') {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => FireHydrantReportPage(taskId: taskId, toolName: toolName)));
       Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FireHydrantReportPage(
                taskId: taskId,
                toolName: toolName,
              ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigate to Fire Hydrant Report')),
      );
    } else if (type == 'hose reel') {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => HoseReelReportPage(taskId: taskId, toolName: toolName)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigate to Hose Reel Report')),
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
            'المواقع - المهام الدورية',
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
                    final toolsInPlace = _toolsForPlace(code);

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
                            toolsInPlace.isEmpty
                                ? [
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'لا يوجد أدوات مسندة لهذا المكان',
                                    ),
                                  ),
                                ]
                                : toolsInPlace.map((tool) {
                                  return ListTile(
                                    title: Text(tool['tool_name'] ?? ''),
                                    subtitle: Text(tool['tool_type'] ?? ''),
                                    onTap:
                                        () => _navigateToReport(context, tool),
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
