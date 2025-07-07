import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/head/Review/ReviewHoseReel.dart';
import 'package:FireWatch/head/Review/ReviewFireHydrant.dart';
import 'package:FireWatch/head/Review/ReviewFireExtinguisher.dart';

class HeadPeriodicLocationsPage extends StatefulWidget {
  const HeadPeriodicLocationsPage({super.key});

  @override
  State<HeadPeriodicLocationsPage> createState() =>
      _HeadPeriodicLocationsPageState();
}

class _HeadPeriodicLocationsPageState extends State<HeadPeriodicLocationsPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> periodicTasks = [];
  bool showApproved = false;
  String headName = 'رئيس الشعبة';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('🔄 Starting _loadData...');
      setState(() => loading = true);

      final user = supabase.auth.currentUser;
      if (user != null) {
        final userInfo =
            await supabase
                .from('users')
                .select('name')
                .eq('id', user.id)
                .maybeSingle();
        headName = userInfo?['name'] ?? 'رئيس الشعبة';
        print('✅ Head name: $headName');
      }

      final locs = await supabase.from('locations').select('id, name, code');
      print('✅ Fetched ${locs.length} locations');

      final tasks = await supabase
          .from('periodic_tasks')
          .select(
            'id, tool_id, status, safety_tools(id, name, type, location_id)',
          );
      print('✅ Fetched ${tasks.length} periodic tasks');

      List<Map<String, dynamic>> list = [];

      for (final t in tasks) {
        final tool = t['safety_tools'];
        if (tool == null) continue;

        final Map<String, dynamic> location = locs.firstWhere(
          (loc) => loc['id'] == tool['location_id'],
          orElse: () => <String, dynamic>{},
        );
        if (location.isEmpty) continue;

        // ✅ Fetch head_approved based on tool type
        final toolType = (tool['type'] ?? '').toString().toLowerCase();
        bool isReviewed = false;

        if (toolType == 'fire extinguisher') {
          final report =
              await supabase
                  .from('fire_extinguisher_reports')
                  .select('head_approved')
                  .eq('task_id', t['id'])
                  .maybeSingle();
          isReviewed = report?['head_approved'] == true;
        } else if (toolType == 'fire hydrant') {
          final report =
              await supabase
                  .from('fire_hydrant_reports')
                  .select('head_approved')
                  .eq('task_id', t['id'])
                  .maybeSingle();
          isReviewed = report?['head_approved'] == true;
        } else if (toolType == 'hose reel') {
          final report =
              await supabase
                  .from('hose_reel_reports')
                  .select('head_approved')
                  .eq('task_id', t['id'])
                  .maybeSingle();
          isReviewed = report?['head_approved'] == true;
        }

        list.add({
          'task_id': t['id'],
          'tool_id': t['tool_id'],
          'tool_name': tool['name'],
          'tool_type': tool['type'],
          'location_code': location['code'],
          'status': t['status'],
          'head_approved': isReviewed, // ✅ inject into task
        });
      }

      setState(() {
        locations = List<Map<String, dynamic>>.from(locs);
        periodicTasks = list;
        loading = false;
      });

      print('✅ _loadData finished successfully');
    } catch (e, stack) {
      print('❌ Error in _loadData: $e');
      print('📌 Stack trace:\n$stack');
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> _tasksForLocation(String code) {
    return periodicTasks.where((task) {
      final match =
          (task['location_code'] ?? '').toString().trim().toUpperCase() ==
          code.toString().trim().toUpperCase();

      final isDoneByTechnician = task['status'] == 'done';
      final isReviewed = task['head_approved'] == true;

      return match &&
          isDoneByTechnician &&
          (!isReviewed ||
              showApproved); // show unreviewed, or reviewed if toggled
    }).toList();
  }

  void _navigateToReviewPage(
    BuildContext context,
    Map<String, dynamic> task,
  ) async {
    final toolType = (task['tool_type'] ?? '').toString().toLowerCase();
    final taskId = task['task_id'];
    final toolName = task['tool_name'];

    if (toolType == 'fire extinguisher') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FireExtinguisherHeadReviewPage(
                taskId: taskId,
                toolName: toolName,
                headName: headName,
                taskType: 'دوري',
              ),
        ),
      );
    } else if (toolType == 'fire hydrant') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FireHydrantHeadReviewPage(
                taskId: taskId,
                toolName: toolName,
                headName: headName,
                taskType: 'دوري',
              ),
        ),
      );
    } else if (toolType == 'hose reel') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => HoseReelHeadReviewPage(
                taskId: taskId,
                toolName: toolName,
                headName: headName,
                taskType: 'دوري',
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
          title: const Text(
            'مراجعة المهام الدورية',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Row(
              children: [
                const Text(
                  'عرض المعتمدة',
                  style: TextStyle(color: Colors.white),
                ),
                Switch(
                  value: showApproved,
                  onChanged: (val) => setState(() => showApproved = val),
                ),
              ],
            ),
          ],
        ),
        body:
            loading
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
                    final tasksInLocation = _tasksForLocation(code);
                    final remaining =
                        periodicTasks.where((task) {
                          final match =
                              (task['location_code'] ?? '')
                                  .toString()
                                  .trim()
                                  .toUpperCase() ==
                              code.toString().trim().toUpperCase();

                          final isDoneByTechnician = task['status'] == 'done';
                          final isReviewed = task['head_approved'] == true;

                          return match &&
                              isDoneByTechnician &&
                              (!isReviewed || showApproved);
                        }).length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          '$name ($code) - $remaining مهام',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children:
                            tasksInLocation.isEmpty
                                ? [
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('لا يوجد أدوات في هذا المكان'),
                                  ),
                                ]
                                : tasksInLocation.map((task) {
                                  final isReviewed =
                                      task['head_approved'] == true;

                                  return ListTile(
                                    title: Text(
                                      task['tool_name'] ?? '',
                                      style: TextStyle(
                                        color:
                                            isReviewed
                                                ? Colors.green
                                                : Colors.orange,
                                        fontWeight:
                                            isReviewed
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(task['tool_type'] ?? ''),
                                    trailing: Text(
                                      isReviewed
                                          ? 'تمت المراجعة'
                                          : 'بانتظار المراجعة',
                                      style: TextStyle(
                                        color:
                                            isReviewed
                                                ? Colors.green
                                                : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onTap:
                                        () => _navigateToReviewPage(
                                          context,
                                          task,
                                        ),
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
