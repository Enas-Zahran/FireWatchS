import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddEmergencyTaskTechnicianPage extends StatefulWidget {
  static const routeName = 'addEmergencyTaskTechnicianPage';

  const AddEmergencyTaskTechnicianPage({super.key});

  @override
  State<AddEmergencyTaskTechnicianPage> createState() =>
      _AddEmergencyTaskTechnicianPageState();
}

class _AddEmergencyTaskTechnicianPageState
    extends State<AddEmergencyTaskTechnicianPage> {
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
        'created_by_role': 'فني السلامة العامة', // This is the only change!
        'is_approved': false, // Must be approved by manager
        'task_type': 'طارئ',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال المهمة الطارئة للمدير للموافقة')),
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
    return Scaffold(
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
              _buildToolSearchField(),
              const SizedBox(height: 16),
              _buildField('المساحة التي تمت تغطيتها', _areaController),
              const SizedBox(height: 16),
              _buildField('سبب الاستخدام', _reasonController),
              const SizedBox(height: 16),
              _buildField('الإجراء المتخذ', _actionController),
              const SizedBox(height: 24),
              Container(
                width: 400,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('إرسال للموافقة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 400,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildToolSearchField() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 400,
        child: TypeAheadField<String>(
          suggestionsCallback: (pattern) {
            return toolNames
                .where(
                  (name) => name.toLowerCase().contains(pattern.toLowerCase()),
                )
                .toList();
          },
          builder: (context, controller, focusNode) {
            _toolController.text = controller.text; // keep controller updated
            return TextField(
              controller: controller,
              focusNode: focusNode,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'رمز أداة السلامة',
                border: OutlineInputBorder(),
              ),
            );
          },
          itemBuilder: (context, String suggestion) {
            return ListTile(
              title: Text(suggestion, textDirection: TextDirection.rtl),
            );
          },
          onSelected: (String suggestion) {
            _toolController.text = suggestion;
            selectedToolName = suggestion;
          },
          emptyBuilder:
              (context) =>
                  const ListTile(title: Text('لم يتم العثور على نتائج')),
        ),
      ),
    );
  }
}
