import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class PeriodicTasksPage extends StatefulWidget {
  const PeriodicTasksPage({super.key});

  @override
  State<PeriodicTasksPage> createState() => _PeriodicTasksPageState();
}

class _PeriodicTasksPageState extends State<PeriodicTasksPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _techSearchController = TextEditingController();
  final TextEditingController _toolSearchController = TextEditingController();

  String? selectedTechnicianId;
  String? selectedTechnicianName;
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> tools = [];
  List<Map<String, dynamic>> locations = [];
  List<String> selectedToolIds = [];
  List<Map<String, dynamic>> assignments = [];
  Map<String, int> taskCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchLocations().then((_) async {
      await _fetchTaskCounts();
      _fetchTechnicians();
      _fetchTools();
    });
  }

  Future<void> _fetchLocations() async {
    final response = await supabase.from('locations').select('id, name, code');
    locations = List<Map<String, dynamic>>.from(response);
  }

  Future<void> _fetchTaskCounts() async {
    final periodic = await supabase
        .from('periodic_tasks')
        .select('assigned_to');
    final corrective = await supabase
        .from('corrective_tasks')
        .select('assigned_to');
    final emergency = await supabase
        .from('emergency_tasks')
        .select('assigned_to');

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

  Future<void> _fetchTechnicians() async {
    final response = await supabase
        .from('users')
        .select('id, name')
        .eq('role', 'فني السلامة العامة')
        .eq('is_approved', true);

    setState(() {
      technicians =
          List<Map<String, dynamic>>.from(response).map((tech) {
            final count = taskCounts[tech['id']] ?? 0;
            return {
              'id': tech['id'],
              'name': tech['name'],
              'assignedPercent': '$count مهمة',
            };
          }).toList();
    });
  }

  Future<void> _fetchTools() async {
    final response = await supabase
        .from('safety_tools')
        .select('id, name, next_maintenance_date, type, material_type')
        .lte(
          'next_maintenance_date',
          DateTime.now()
              .add(const Duration(days: 6))
              .copyWith(hour: 23, minute: 59, second: 59)
              .toIso8601String()
              .substring(0, 10),
        );

    // assignments = await supabase
    //     .from('periodic_tasks')
    //     .select('tool_id, assigned_to');
    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(const Duration(hours: 24)).toIso8601String();

    assignments = await supabase
        .from('periodic_tasks')
        .select('tool_id, assigned_to, assigned_at')
        .gte('assigned_at', cutoff);

    setState(() {
      tools =
          List<Map<String, dynamic>>.from(response).map((tool) {
            final assignment = assignments.firstWhere(
              (a) => a['tool_id'] == tool['id'],
              orElse: () => {},
            );
            final isAssigned = assignment.isNotEmpty;
            final assignedTo = assignment['assigned_to'];
            return {
              'id': tool['id'],
              'name': tool['name'],
              'nextMaintenance': tool['next_maintenance_date'],
              'assigned': isAssigned,
              'assignedTo': assignedTo,
              'locationName': _getLocationNameFromToolName(tool['name']),
              'type': tool['type'],
              'material_type': tool['material_type'],
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
    final filteredTechnicians =
        technicians.where((tech) {
          return tech['name'].toString().toLowerCase().contains(
            _techSearchController.text.toLowerCase(),
          );
        }).toList();

    final keyword = _toolSearchController.text.trim();
    final filteredTools =
        tools.where((tool) {
          return tool['name'].toString().toLowerCase().contains(
                keyword.toLowerCase(),
              ) ||
              (tool['locationName'] ?? '').startsWith(keyword.toLowerCase());
        }).toList();

    final selectedRatio =
        filteredTools.isEmpty
            ? '0%'
            : '${((selectedToolIds.length / filteredTools.length) * 100).toStringAsFixed(0)}%';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المهام الدورية',
            style: TextStyle(color: Colors.white),
          ),
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
              Text(
                'عدد الأدوات المحددة: ${selectedToolIds.length} من ${filteredTools.length} ($selectedRatio)',
              ),
              if (selectedTechnicianName != null)
                Text('  الفني المحدد :$selectedTechnicianName'),
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
                              selectedToolIds =
                                  filteredTools
                                      .map((t) => t['id'] as String)
                                      .toList();
                            });
                          },
                          child: const Text('تحديد الكل'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedToolIds.clear();
                            });
                          },
                          child: const Text('إلغاء التحديد الكلي'),
                        ),
                        TextField(
                          controller: _toolSearchController,
                          decoration: const InputDecoration(
                            labelText:
                                '🔍 اكتب أول حرف من الموقع أو اسم الأداة',
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
                        children:
                            filteredTools.map((tool) {
                              final toolId = tool['id'];
                              final isSelected = selectedToolIds.contains(
                                toolId,
                              );
                              final assignedTo = tool['assignedTo'];
                              final nextMaintenance =
                                  tool['nextMaintenance'] ?? '';
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
                                  '${tool['name']} - ${tool['locationName']}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الصيانة القادمة: $nextMaintenance'),
                                    if (assignedToAnother)
                                      const Text(
                                        '❗ هذه المهمة مسندة لمستخدم آخر',
                                      ),
                                  ],
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedToolIds.remove(toolId);
                                      } else {
                                        selectedToolIds.add(toolId);
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
                        children:
                            filteredTechnicians.map((tech) {
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
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed:
                    selectedTechnicianId != null && selectedToolIds.isNotEmpty
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

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الإسناد'),
              content: const Text(
                'هل أنت متأكد من اضافة هذه المهام لهذا المستخدم؟',
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final toolDetails =
                        tools
                            .where(
                              (tool) => selectedToolIds.contains(tool['id']),
                            )
                            .toList();

                    // استخراج القيم الفريدة من الأدوات المسندة
                    final toolTypes = <String>{};
                    final materialTypes = <String>{};
                    final workPlaces = <String>{};

                    for (final tool in toolDetails) {
                      final type = tool['type']?.toString();
                      final material = tool['material_type']?.toString();
                      final location = tool['locationName']?.toString();

                      if (type != null && type.isNotEmpty) toolTypes.add(type);
                      if (material != null && material.isNotEmpty)
                        materialTypes.add(material);
                      if (location != null && location.isNotEmpty)
                        workPlaces.add(location);
                    }

                    for (final toolId in selectedToolIds) {
                      await supabase.from('periodic_tasks').insert({
                        'tool_id': toolId,
                        'assigned_to': selectedTechnicianId,
                        'assigned_by': supabase.auth.currentUser!.id,
                        'assigned_at': DateTime.now().toUtc().toIso8601String(),
                      });
                    }

                    final userData =
                        await supabase
                            .from('users')
                            .select()
                            .eq('id', selectedTechnicianId!)
                            .single();

                    // ✅ Safe merging function
                    List<String> updateList(
                      dynamic current,
                      Set<String> newValues,
                    ) {
                      try {
                        if (current is List) {
                          return {
                            ...current.cast<String>(),
                            ...newValues,
                          }.toList();
                        } else if (current is String &&
                            current.trim().startsWith('[')) {
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

                    final updatedToolTypes = updateList(
                      userData['tool_type'],
                      toolTypes,
                    );
                    final updatedMaterialTypes = updateList(
                      userData['material_type'],
                      materialTypes,
                    );
                    final updatedWorkPlaces = updateList(
                      userData['work_place'],
                      workPlaces,
                    );
                    final updatedTaskCount =
                        (userData['task_count'] ?? 0) + selectedToolIds.length;
                    await supabase
                        .from('users')
                        .update({
                          'tool_type': toolTypes.toList(), // ✅ This is good now
                          'material_type':
                              materialTypes.toList(), // ✅ Also good
                          'work_place': updatedWorkPlaces,
                        })
                        .eq('id', selectedTechnicianId!);

                    Navigator.pop(context);
                    setState(() => selectedToolIds.clear());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إسناد المهام وتحديث الفني بنجاح'),
                      ),
                    );

                    await _fetchTaskCounts();
                    _fetchTechnicians();
                    _fetchTools();
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
}
