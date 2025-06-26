import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyTasksPage extends StatefulWidget {
  static const routeName = 'emergencyTasksPage';
  const EmergencyTasksPage({super.key});

  @override
  State<EmergencyTasksPage> createState() => _EmergencyTasksPageState();
}

class _EmergencyTasksPageState extends State<EmergencyTasksPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _techSearchController = TextEditingController();
  final TextEditingController _toolSearchController = TextEditingController();

  String? selectedTechnicianId;
  String? selectedTechnicianName;
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> locations = [];
  List<String> selectedRequestIds = [];
  List<Map<String, dynamic>> assignments = [];
  Map<String, int> taskCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchLocations().then((_) async {
      await _fetchTaskCounts();
      _fetchTechnicians();
      _fetchRequests();
    });
  }

  Future<void> _fetchTaskCounts() async {
    final periodic = await supabase.from('periodic_tasks').select('assigned_to');
    final corrective = await supabase.from('corrective_tasks').select('assigned_to');
    final emergency = await supabase.from('emergency_tasks').select('assigned_to');

    final all = [...periodic, ...corrective, ...emergency];
    final counts = <String, int>{};
    for (final task in all) {
      final id = task['assigned_to'];
      if (id != null) {
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    setState(() => taskCounts = counts);
  }

  Future<void> _fetchLocations() async {
    final response = await supabase.from('locations').select('id, name, code');
    locations = List<Map<String, dynamic>>.from(response);
  }

  Future<void> _fetchTechnicians() async {
    final response = await supabase
        .from('users')
        .select('id, name')
        .eq('role', 'فني السلامة العامة');

    setState(() {
      technicians = List<Map<String, dynamic>>.from(response).map((tech) {
        final count = taskCounts[tech['id']] ?? 0;
        return {
          'id': tech['id'],
          'name': tech['name'],
          'assignedPercent': '$count مهمة',
        };
      }).toList();
    });
  }

  Future<void> _fetchRequests() async {
    final response = await supabase
        .from('emergency_requests')
        .select()
        .eq('is_approved', true)
        .eq('task_type', 'طارئ');

    assignments = await supabase.from('emergency_tasks').select('request_id, assigned_to');

    setState(() {
      requests = List<Map<String, dynamic>>.from(response).map((req) {
        final assignment = assignments.firstWhere(
          (a) => a['request_id'] == req['id'],
          orElse: () => {},
        );
        final isAssigned = assignment.isNotEmpty;
        final assignedTo = assignment['assigned_to'];
        return {
          'id': req['id'],
          'tool': req['tool_code'],
          'area': req['covered_area'],
          'reason': req['usage_reason'],
          'action': req['action_taken'],
          'assigned': isAssigned,
          'assignedTo': assignedTo,
          'locationName': _getLocationNameFromToolName(req['tool_code']),
        };
      }).toList();
    });
  }

  String _getLocationNameFromToolName(String? toolName) {
    if (toolName == null || toolName.isEmpty) return 'غير معروف';
    final firstChar = toolName[0].toUpperCase();
    final match = locations.firstWhere(
      (loc) => (loc['code'] ?? '').toString().toUpperCase() == firstChar,
      orElse: () => {},
    );
    return match['name'] ?? 'غير معروف';
  }

  @override
  Widget build(BuildContext context) {
    final filteredTechnicians = technicians.where((tech) {
      return tech['name'].toString().toLowerCase().contains(_techSearchController.text.toLowerCase());
    }).toList();

    final keyword = _toolSearchController.text.trim();
    final filteredRequests = requests.where((req) {
      return req['tool'].toString().toLowerCase().contains(keyword.toLowerCase()) ||
          (req['locationName'] ?? '').toLowerCase().startsWith(keyword.toLowerCase());
    }).toList();

    final selectedRatio = filteredRequests.isEmpty
        ? '0%'
        : '${((selectedRequestIds.length / filteredRequests.length) * 100).toStringAsFixed(0)}%';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المهام الطارئة', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text('عدد الطلبات المحددة: ${selectedRequestIds.length} من ${filteredRequests.length} ($selectedRatio)'),
              if (selectedTechnicianName != null)
                Text('الفني المحدد : $selectedTechnicianName '),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedRequestIds = filteredRequests.map((r) => r['id'] as String).toList();
                            });
                          },
                          child: const Text('تحديد الكل'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedRequestIds.clear();
                            });
                          },
                          child: const Text('إلغاء التحديد الكلي'),
                        ),
                        TextField(
                          controller: _toolSearchController,
                          decoration: const InputDecoration(
                            labelText: '🔍 اكتب أول حرف من الموقع أو اسم الأداة',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _techSearchController,
                      decoration: const InputDecoration(
                        labelText: '🔍 ابحث عن اسم الفني',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ListView(
                        children: filteredRequests.map((req) {
                          final reqId = req['id'];
                          final isSelected = selectedRequestIds.contains(reqId);
                          final assignedTo = req['assignedTo'];
                          final assignedToAnother = assignedTo != null && assignedTo != selectedTechnicianId;
                          final assignedToThisTech = assignedTo != null && assignedTo == selectedTechnicianId;
                          return ListTile(
                            tileColor: assignedToAnother
                                ? Colors.red[100]
                                : assignedToThisTech
                                    ? Colors.green[100]
                                    : null,
                            title: Text('${req['tool']} - ${req['locationName']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('المساحة المغطاة: ${req['area']}'),
                                Text('السبب: ${req['reason']}'),
                                Text('الإجراء: ${req['action']}'),
                                if (assignedToAnother)
                                  const Text('❗ تم إسناد هذا الطلب لمستخدم آخر'),
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (isSelected) {
                                    selectedRequestIds.remove(reqId);
                                  } else {
                                    selectedRequestIds.add(reqId);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListView(
                        children: filteredTechnicians.map((tech) {
                          return Card(
                            color: selectedTechnicianId == tech['id'] ? Colors.blue[100] : null,
                            child: ListTile(
                              title: Text(tech['name']),
                              subtitle: Text('عدد المهام: ${tech['assignedPercent']}'),
                              onTap: () {
                                setState(() {
                                  selectedTechnicianId = tech['id'];
                                  selectedTechnicianName = tech['name'];
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: selectedTechnicianId != null && selectedRequestIds.isNotEmpty
                    ? () => _showConfirmationDialog(context)
                    : null,
                child: const Text('إضافة المهام'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الإسناد'),
          content: const Text('هل أنت متأكد من اضافة هذه المهام لهذا المستخدم؟'),
          actions: [
          
            TextButton(
              onPressed: () async {
                for (final requestId in selectedRequestIds) {
                  final request = requests.firstWhere((r) => r['id'] == requestId);
                  final toolName = request['tool'];
                  final tool = await supabase
                      .from('safety_tools')
                      .select('id')
                      .eq('name', toolName)
                      .maybeSingle();
                  await supabase.from('emergency_tasks').insert({
                    'request_id': requestId,
                    'tool_id': tool != null ? tool['id'] : null,
                    'assigned_to': selectedTechnicianId,
                    'assigned_by': supabase.auth.currentUser!.id,
                    'due_date': DateTime.now().add(const Duration(days: 6)).toIso8601String(),
                  });
                }
                Navigator.pop(context);
                setState(() => selectedRequestIds.clear());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إسناد المهام بنجاح')));
                await _fetchTaskCounts();
                _fetchTechnicians();
                _fetchRequests();
              },
              child: const Text('نعم'),
            ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('لا')),
          ],
        ),
      ),
    );
  }
}
