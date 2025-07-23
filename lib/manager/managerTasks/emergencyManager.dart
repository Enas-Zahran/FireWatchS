// Full refactored EmergencyTasksPage with assignment like CorrectiveTasksPage
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class EmergencyTasksPage extends StatefulWidget {
  static const routeName = 'emergencyTasksPage';
  const EmergencyTasksPage({super.key});

  @override
  State<EmergencyTasksPage> createState() => _EmergencyTasksPageState();
}

class _EmergencyTasksPageState extends State<EmergencyTasksPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _toolSearchController = TextEditingController();
  final TextEditingController _techSearchController = TextEditingController();

  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> locations = [];
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> assignments = [];
  List<String> selectedRequestIds = [];
  String? selectedTechnicianId;
  String? selectedTechnicianName;
  Map<String, int> taskCounts = {};
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
      await _fetchTaskCounts();
      await _fetchTechnicians();
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

  Future<void> _fetchTaskCounts() async {
    final tasks = await supabase.from('emergency_tasks').select('assigned_to');
    final counts = <String, int>{};
    for (final task in tasks) {
      final id = task['assigned_to'];
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    taskCounts = counts;
  }

  Future<void> _fetchTechnicians() async {
    final response = await supabase
        .from('users')
        .select('id, name, is_approved')
        .eq('role', 'فني السلامة العامة')
        .eq('is_approved', true);

    technicians =
        List<Map<String, dynamic>>.from(response).map((tech) {
          final count = taskCounts[tech['id']] ?? 0;
          return {
            'id': tech['id'],
            'name': tech['name'],
            'assignedPercent': '$count مهمة',
          };
        }).toList();
  }

  Future<void> _fetchRequests() async {
    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(const Duration(hours: 24));

    final response = await supabase
        .from('emergency_requests')
        .select()
        .eq('is_approved', true)
        .eq('task_type', 'طارئ');

    final assignmentResponse = await supabase
        .from('emergency_tasks')
        .select('request_id, assigned_to, assigned_at');

    assignments = List<Map<String, dynamic>>.from(assignmentResponse);

    requests =
        List<Map<String, dynamic>>.from(response)
            .where((req) {
              final assignment = assignments.firstWhere(
                (a) => a['request_id'] == req['id'],
                orElse: () => {},
              );

              final isAssigned = assignment.isNotEmpty;
              final assignedAtRaw = assignment['assigned_at'];

              if (isAssigned && assignedAtRaw != null) {
                try {
                  final assignedAt = DateTime.parse(assignedAtRaw);
                  if (assignedAt.isBefore(cutoff)) {
                    return false; // ❌ إخفاء المهمة لأنها قديمة
                  }
                } catch (e) {
                  print('⚠️ خطأ في تاريخ الإسناد: $e');
                }
              }

              return true; // ✅ إظهار التقرير إذا لم يكن مسند أو تم إسناده حديثًا
            })
            .map((req) {
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
            })
            .toList();
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الإسناد'),
              content: const Text(
                'هل أنت متأكد من إضافة هذه المهام لهذا المستخدم؟',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _assignTasks();
                  },
                  child: const Text('نعم'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('لا'),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _assignTasks() async {
    if (selectedTechnicianId == null || selectedRequestIds.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final toolNames =
          selectedRequestIds.map((id) {
            return requests.firstWhere((r) => r['id'] == id)['tool'];
          }).toList();

      final toolResponse = await supabase
          .from('safety_tools')
          .select('id, name, type, material_type')
          .inFilter('name', toolNames);

      final toolMap = {for (var tool in toolResponse) tool['name']: tool['id']};

      final tasks =
          selectedRequestIds.map((id) {
            final req = requests.firstWhere((r) => r['id'] == id);
            return {
              'request_id': id,
              'assigned_to': selectedTechnicianId,
              'assigned_by': supabase.auth.currentUser!.id,
              'assigned_at': DateTime.now().toUtc().toIso8601String(),
              'due_date':
                  DateTime.now().add(const Duration(days: 6)).toIso8601String(),
              'tool_id': toolMap[req['tool']],
            };
          }).toList();

      await supabase.from('emergency_tasks').insert(tasks);

      final toolDetails =
          requests.where((r) => selectedRequestIds.contains(r['id'])).toList();
      final toolTypes = <String>{};
      final materialTypes = <String>{};
      final workPlaces = <String>{};

      for (final req in toolDetails) {
        final toolName = req['tool']?.toString();
        if (toolName == null || toolName.isEmpty) continue;

        final matchingTool =
            await supabase
                .from('safety_tools')
                .select('type, material_type')
                .eq('name', toolName)
                .maybeSingle();

        final type = matchingTool?['type']?.toString();
        final material = matchingTool?['material_type']?.toString();
        final location = req['locationName']?.toString();

        if (type != null && type.isNotEmpty) toolTypes.add(type);
        if (material != null && material.isNotEmpty)
          materialTypes.add(material);
        if (location != null && location.isNotEmpty) workPlaces.add(location);
      }

      final userData =
          await supabase
              .from('users')
              .select()
              .eq('id', selectedTechnicianId!)
              .single();

      List<String> updateList(dynamic current, Set<String> newValues) {
        try {
          if (current is List) {
            return {...current.cast<String>(), ...newValues}.toList();
          } else if (current is String && current.trim().startsWith('[')) {
            final parsed = jsonDecode(current);
            if (parsed is List) {
              return {
                ...parsed.map((e) => e.toString()),
                ...newValues,
              }.toList();
            }
          }
        } catch (_) {}
        return newValues.toList();
      }

      final updatedToolTypes = updateList(userData['tool_type'], toolTypes);
      final updatedMaterialTypes = updateList(
        userData['material_type'],
        materialTypes,
      );
      final updatedWorkPlaces = updateList(userData['work_place'], workPlaces);
      final updatedTaskCount =
          (userData['task_count'] ?? 0) + selectedRequestIds.length;

      await supabase
          .from('users')
          .update({
            'tool_type': updatedToolTypes,
            'material_type': updatedMaterialTypes,
            'work_place': updatedWorkPlaces,
            'task_count': updatedTaskCount,
          })
          .eq('id', selectedTechnicianId!);

      setState(() => selectedRequestIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إسناد المهام وتحديث الفني بنجاح')),
      );

      await _loadInitialData();
    } catch (e) {
      _showErrorSnackbar('فشل في الإسناد: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTechnicians =
        technicians.where((tech) {
          return tech['name'].toString().toLowerCase().contains(
            _techSearchController.text.toLowerCase(),
          );
        }).toList();

    final keyword = _toolSearchController.text.trim();
    final filteredRequests =
        requests.where((req) {
          return req['tool'].toString().toLowerCase().contains(
                keyword.toLowerCase(),
              ) ||
              (req['locationName'] ?? '').toLowerCase().startsWith(
                keyword.toLowerCase(),
              );
        }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المهام الطارئة',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _toolSearchController,
                              decoration: const InputDecoration(
                                labelText:
                                    '🔍 اكتب أول حرف من الموقع أو اسم الأداة',
                              ),
                              onChanged: (_) => setState(() {}),
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
                      const SizedBox(height: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredRequests.length,
                                itemBuilder: (context, index) {
                                  final req = filteredRequests[index];
                                  final reqId = req['id'];
                                  final isSelected = selectedRequestIds
                                      .contains(reqId);
                                  final assignedTo = req['assignedTo'];
                                  final assignedToAnother =
                                      assignedTo != null &&
                                      assignedTo != selectedTechnicianId;
                                  final assignedToThisTech =
                                      assignedTo != null &&
                                      assignedTo == selectedTechnicianId;

                                  return ListTile(
                                    tileColor:
                                        assignedToAnother
                                            ? Colors.red[100]
                                            : assignedToThisTech
                                            ? Colors.green[100]
                                            : null,
                                    title: Text(
                                      '${req['tool']} - ${req['locationName']}',
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('المساحة: ${req['area']}'),
                                        Text('السبب: ${req['reason']}'),
                                        Text('الإجراء: ${req['action']}'),
                                        if (assignedToAnother)
                                          const Text(
                                            '❗ تم إسناد هذا البلاغ لمستخدم آخر',
                                          ),
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
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredTechnicians.length,
                                itemBuilder: (context, index) {
                                  final tech = filteredTechnicians[index];
                                  return Card(
                                    color:
                                        selectedTechnicianId == tech['id']
                                            ? Colors.blue[100]
                                            : null,
                                    child: ListTile(
                                      title: Text(tech['name']),
                                      subtitle: Text(
                                        'عدد المهام: ${tech['assignedPercent']}',
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedTechnicianId = tech['id'];
                                          selectedTechnicianName = tech['name'];
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            selectedTechnicianId != null &&
                                    selectedRequestIds.isNotEmpty
                                ? () => _showConfirmationDialog(context)
                                : null,
                        child: const Text('إضافة المهام'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
