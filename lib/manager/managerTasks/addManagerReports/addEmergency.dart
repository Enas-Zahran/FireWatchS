import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/customFields.dart';

class AddEmergencyTaskManagerPage extends StatefulWidget {
  static const routeName = 'addEmergencyTaskManagerPage';

  const AddEmergencyTaskManagerPage({super.key});

  @override
  State<AddEmergencyTaskManagerPage> createState() =>
      _AddEmergencyTaskManagerPageState();
}

class _AddEmergencyTaskManagerPageState
    extends State<AddEmergencyTaskManagerPage> {
  final _areaController = TextEditingController();
  final _reasonController = TextEditingController();
  final _actionController = TextEditingController();
  final _toolController = TextEditingController();

  final supabase = Supabase.instance.client;
  List<String> toolNames = [];
  String? selectedToolName;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadToolNames();
  }

  Future<void> _loadToolNames() async {
    final response = await supabase.from('safety_tools').select('name');
    setState(() {
      toolNames = List<String>.from(response.map((e) => e['name'] as String));
    });
  }

  Future<void> _submit() async {
    if (_toolController.text.isEmpty ||
        _areaController.text.isEmpty ||
        _reasonController.text.isEmpty ||
        _actionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى تعبئة جميع الحقول')));
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      await supabase.from('emergency_requests').insert({
        'tool_code': _toolController.text.trim(),
        'covered_area': _areaController.text,
        'usage_reason': _reasonController.text,
        'action_taken': _actionController.text,
        'created_by': user?.id,
        'created_by_role': 'المدير',
        'is_approved': true,
        'task_type': 'طارئ',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المهمة الطارئة بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ أثناء الإرسال: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text('اضافة طارئ', style: TextStyle(color: Colors.white)),
          ),
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: ListView(
              children: [
                buildToolSearchField(
                  toolNames: toolNames,
                  controller: _toolController,
                  onSelected: (suggestion) {
                    _toolController.text = suggestion;
                    selectedToolName = suggestion;
                  },
                ),

                const SizedBox(height: 16),
                buildCustomField(
                  label: 'المساحة التي تمت تغطيتها',
                  controller: _areaController,
                ),
                const SizedBox(height: 16),
                buildCustomField(
                  label: 'سبب الاستخدام',
                  controller: _reasonController,
                ),
                const SizedBox(height: 16),
                buildCustomField(
                  label: 'الإجراء المتخذ',
                  controller: _actionController,
                ),
                const SizedBox(height: 24),
                Container(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child:
                        isLoading
                            ? const CircularProgressIndicator()
                            : const Text('إضافة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  
}
