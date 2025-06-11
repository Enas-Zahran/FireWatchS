import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ToolReassignPage extends StatefulWidget {
  final String taskId;
  const ToolReassignPage({super.key, required this.taskId});

  @override
  State<ToolReassignPage> createState() => _ToolReassignPageState();
}

class _ToolReassignPageState extends State<ToolReassignPage> {
  Map<String, dynamic>? task;
  List<Map<String, dynamic>> technicians = [];
  String? selectedTechnicianId;
  String? selectedTechnicianName;
  bool _loading = true;
  bool _assigning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTaskAndTechs();
  }

  Future<void> _fetchTaskAndTechs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch task details
      final data =
          await Supabase.instance.client
              .from('periodic_tasks')
              .select(
                'id, assigned_at, due_date, completed, assigned_to, tool_id, safety_tools(name), users!assigned_to(name)',
              )
              .eq('id', widget.taskId)
              .maybeSingle();
      // Fetch technicians
      final techs = await Supabase.instance.client
          .from('users')
          .select('id, name')
          .eq('role', 'فني السلامة العامة');
      setState(() {
        task = data;
        technicians = List<Map<String, dynamic>>.from(techs);
        selectedTechnicianId = task?['assigned_to'];
        selectedTechnicianName = task?['users']?['name'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء جلب البيانات.';
        _loading = false;
      });
    }
  }

  Future<void> _reassignTask() async {
    if (selectedTechnicianId == null) return;
    setState(() => _assigning = true);
    try {
      await Supabase.instance.client
          .from('periodic_tasks')
          .update({
            'assigned_to': selectedTechnicianId,
            'assigned_at': DateTime.now().toIso8601String(),
            'completed': false,
          })
          .eq('id', widget.taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إعادة إسناد المهمة بنجاح')),
      );
      Navigator.pop(
        context,
        true,
      ); // You can use this to trigger refresh on previous page
    } catch (e) {
      setState(() => _assigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء إعادة الإسناد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إعادة إسناد المهمة'),
          backgroundColor: const Color(0xff00408b),
        ),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    final toolName = task?['safety_tools']?['name'] ?? '';
    final assignedName = selectedTechnicianName ?? 'غير محدد';
    final assignedDate =
        task?['assigned_at']?.toString().split('T').first ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: Center(child: Text(toolName, style: const TextStyle(color: Colors.white))),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'هذه المهمة اسندت ل $assignedName',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                'اسندت بتاريخ $assignedDate',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              const Text(
                'اختر فني جديد لإعادة الإسناد:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTechnicianId,
                isExpanded: true,
                items:
                    technicians
                        .map(
                          (tech) => DropdownMenuItem<String>(
                            value: tech['id'].toString(), // Ensure it's a String
                            child: Text(tech['name']),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedTechnicianId = val;
                    selectedTechnicianName =
                        technicians.firstWhere(
                          (t) => t['id'].toString() == val,
                        )['name'];
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'اسم الفني',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _assigning ? null : _reassignTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00408b),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child:
                      _assigning
                          ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'إعادة اسناد المهمة',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
