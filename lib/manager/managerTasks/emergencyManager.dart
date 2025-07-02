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

  List<Map<String, dynamic>> requests = [];
  List<Map<String, dynamic>> locations = [];
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
    final response = await supabase
        .from('emergency_requests')
        .select()
        .eq('is_approved', true)
        .eq('task_type', 'طارئ');

    assignments = await supabase
        .from('emergency_tasks')
        .select('request_id, assigned_to');

    setState(() {
      requests =
          List<Map<String, dynamic>>.from(response).map((req) {
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final locationGroups = <String, List<Map<String, dynamic>>>{};
    for (final req in filteredRequests) {
      final loc = req['locationName'];
      locationGroups.putIfAbsent(loc, () => []).add(req);
    }

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
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _toolSearchController,
                        decoration: const InputDecoration(
                          labelText: '🔍 اكتب أول حرف من الموقع أو اسم الأداة',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (locationGroups.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'لا توجد مهام حالياً',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (locationGroups.isNotEmpty)
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children:
                              locationGroups.entries.map((entry) {
                                final loc = entry.key;
                                final tasks = entry.value;
                                final assignedCount =
                                    tasks
                                        .where((t) => t['assigned'] == true)
                                        .length;
                                final total = tasks.length;
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      '$loc - $assignedCount من $total مهمة',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    children:
                                        tasks.map((task) {
                                          final isAssigned =
                                              task['assigned'] == true;
                                          return ListTile(
                                            tileColor:
                                                isAssigned
                                                    ? Colors.green[100]
                                                    : null,
                                            title: Text(
                                              task['tool'] ?? '',
                                              style: TextStyle(
                                                color:
                                                    isAssigned
                                                        ? Colors.green
                                                        : null,
                                                fontWeight:
                                                    isAssigned
                                                        ? FontWeight.bold
                                                        : null,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'المساحة المغطاة: ${task['area']}',
                                                ),
                                                Text(
                                                  'السبب: ${task['reason']}',
                                                ),
                                                Text(
                                                  'الإجراء: ${task['action']}',
                                                ),
                                                if (isAssigned)
                                                  const Text(
                                                    '✅ تم إسناد المهمة',
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}
