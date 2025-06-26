import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:FireWatch/My/customFields.dart';

class AddCorrectiveTaskManagerPage extends StatefulWidget {
  static const String routeName = 'addCorrectiveTaskManagerPage';

  const AddCorrectiveTaskManagerPage({super.key});

  @override
  State<AddCorrectiveTaskManagerPage> createState() =>
      _AddCorrectiveTaskManagerPageState();
}

class _AddCorrectiveTaskManagerPageState
    extends State<AddCorrectiveTaskManagerPage> {
  final supabase = Supabase.instance.client;

  final _problemController = TextEditingController();
  final _informerController = TextEditingController();
  final _actionController = TextEditingController();
  final _toolController = TextEditingController();

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
    if (selectedToolName == null ||
        _problemController.text.isEmpty ||
        _actionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة الحقول المطلوبة')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;

      await supabase.from('emergency_requests').insert({
        'tool_code': selectedToolName,
        'covered_area': '-', // not used in علاجي
        'usage_reason': _problemController.text,
        'action_taken': _actionController.text,
        'created_by': user?.id,
        'created_by_role': 'المدير',
        'is_approved': true,
        'task_type': 'علاجي',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة المهمة العلاجية بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
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
            child: Text('اضافة علاجي', style: TextStyle(color: Colors.white)),
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
                  label: 'الخلل الذي وجد *',
                  controller: _problemController,
                ),
                const SizedBox(height: 16),
                buildCustomField(
                  label: 'من أخبر عنه (اختياري)',
                  controller: _informerController,
                ),
                const SizedBox(height: 16),
                buildCustomField(
                  label: 'الإجراء المتخذ *',
                  controller: _actionController,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 400,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child:
                          isLoading
                              ? const CircularProgressIndicator()
                              : const Text('إضافة'),
                    ),
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
