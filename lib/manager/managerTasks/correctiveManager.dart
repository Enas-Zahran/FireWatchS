import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CorrectiveTasksPage extends StatefulWidget {
  static const routeName = 'correctiveTasksPage';
  const CorrectiveTasksPage({super.key});

  @override
  State<CorrectiveTasksPage> createState() => _CorrectiveTasksPageState();
}

class _CorrectiveTasksPageState extends State<CorrectiveTasksPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _techSearchController = TextEditingController();
  final TextEditingController _toolSearchController = TextEditingController();

  String? selectedTechnicianId;
  String? selectedTechnicianName;
  List<Map<String, dynamic>> technicians = [];
  List<Map<String, dynamic>> reports = [];
  List<Map<String, dynamic>> locations = [];
  List<String> selectedReportIds = [];
  List<Map<String, dynamic>> assignments = [];
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
      await _fetchReports();
    } catch (e) {
      _showErrorSnackbar('Failed to load data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
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

  Future<void> _fetchReports() async {
    final response = await supabase
        .from('emergency_requests')
        .select()
        .eq('is_approved', true)
        .eq('task_type', 'علاجي');

    assignments = await supabase.from('corrective_tasks').select('report_id, assigned_to');

    setState(() {
      reports = List<Map<String, dynamic>>.from(response).map((report) {
        final assignment = assignments.firstWhere(
          (a) => a['report_id'] == report['id'],
          orElse: () => {},
        );
        final isAssigned = assignment.isNotEmpty;
        final assignedTo = assignment['assigned_to'];
        return {
          'id': report['id'],
          'tool': report['tool_code'],
          'reason': report['usage_reason'],
          'action': report['action_taken'],
          'assigned': isAssigned,
          'assignedTo': assignedTo,
          'locationName': _getLocationNameFromToolName(report['tool_code']),
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

  String _getSelectedRatioText(int selected, int total) {
    if (total == 0) return '0%';
    final percentage = (selected / total) * 100;
    return '${percentage.toStringAsFixed(0)}%';
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _assignTasks() async {
    if (selectedTechnicianId == null || selectedReportIds.isEmpty) return;

    setState(() => _isLoading = true);
    try {
     
      final toolNames = selectedReportIds.map((reportId) {
        return reports.firstWhere((r) => r['id'] == reportId)['tool'];
      }).toList();

      final toolResponse = await supabase
          .from('safety_tools')
          .select('id, name')
          .inFilter('name', toolNames);

      final toolMap = {for (var tool in toolResponse) tool['name']: tool['id']};

      // Prepare all tasks
      final tasks = selectedReportIds.map((reportId) {
        final report = reports.firstWhere((r) => r['id'] == reportId);
        return {
          'report_id': reportId,
          'assigned_to': selectedTechnicianId,
          'assigned_by': supabase.auth.currentUser!.id,
          'due_date': DateTime.now().add(const Duration(days: 6)).toIso8601String(),
          'tool_id': toolMap[report['tool']],
        };
      }).toList();


      await supabase.from('corrective_tasks').insert(tasks);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إسناد المهام بنجاح')),
      );

      setState(() {
        selectedReportIds.clear();
      });

      await _fetchTaskCounts();
      await _fetchTechnicians();
      await _fetchReports();
    } catch (e) {
      _showErrorSnackbar('Failed to assign tasks: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الإسناد'),
        content: const Text('هل أنت متأكد من اضافة هذه المهام لهذا المستخدم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _assignTasks();
            },
            child: const Text('نعم'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTechnicians = technicians.where((tech) {
      return tech['name'].toString().toLowerCase().contains(_techSearchController.text.toLowerCase());
    }).toList();

    final keyword = _toolSearchController.text.trim();
    final filteredReports = reports.where((report) {
      return report['tool'].toString().toLowerCase().contains(keyword.toLowerCase()) ||
          (report['locationName'] ?? '').toString().startsWith(keyword.toLowerCase());
    }).toList();

    final selectedRatio = _getSelectedRatioText(
      selectedReportIds.length,
      filteredReports.length,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المهام العلاجية', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text('عدد البلاغات المحددة: ${selectedReportIds.length} من ${filteredReports.length} ($selectedRatio)'),
                    if (selectedTechnicianName != null)
                      Text('  الفني المحدد : $selectedTechnicianName'),
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
                                    selectedReportIds = filteredReports
                                        .map((r) => r['id'] as String)
                                        .toList();
                                  });
                                },
                                child: const Text('تحديد الكل'),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedReportIds.clear();
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
                            child: ListView.builder(
                              itemCount: filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = filteredReports[index];
                                final reportId = report['id'];
                                final isSelected = selectedReportIds.contains(reportId);
                                final assignedTo = report['assignedTo'];
                                final assignedToAnother = assignedTo != null && assignedTo != selectedTechnicianId;
                                final assignedToThisTech = assignedTo != null && assignedTo == selectedTechnicianId;
                                
                                return ListTile(
                                  tileColor: assignedToAnother
                                      ? Colors.red[100]
                                      : assignedToThisTech
                                          ? Colors.green[100]
                                          : null,
                                  title: Text('${report['tool']} - ${report['locationName']}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('الخلل: ${report['reason']}'),
                                      Text('الإجراء: ${report['action']}'),
                                      if (assignedToAnother)
                                        const Text('❗ تم إسناد هذا البلاغ لمستخدم آخر'),
                                    ],
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (val) {
                                      setState(() {
                                        if (isSelected) {
                                          selectedReportIds.remove(reportId);
                                        } else {
                                          selectedReportIds.add(reportId);
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
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedTechnicianId != null && selectedReportIds.isNotEmpty
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
}