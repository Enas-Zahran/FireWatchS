import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

class HoseReelReportPage extends StatefulWidget {
  final String taskId;
  final String toolName;
  final String taskType; // دوري - علاجي - طارئ

  const HoseReelReportPage({
    super.key,
    required this.taskId,
    required this.toolName,
    required this.taskType,
  });

  @override
  State<HoseReelReportPage> createState() => _HoseReelReportPageState();
}

class _HoseReelReportPageState extends State<HoseReelReportPage> {
  final supabase = Supabase.instance.client;
  DateTime? currentDate;
  DateTime? nextDate;
  Map<String, bool> checks = {};
  Map<String, TextEditingController> notes = {};
  final SignatureController technicianSignature = SignatureController(penStrokeWidth: 2);
  final SignatureController companySignature = SignatureController(penStrokeWidth: 2);
  final _formKey = GlobalKey<FormState>();
  final TextEditingController companyRep = TextEditingController();
  String? companyName;
  String? technicianName;
  final TextEditingController otherNotesController = TextEditingController();

  final List<String> steps = [
    'الفحص الأولي لجميع الأجزاء من التأكل والصداء.',
    'التحقق من وصول المياه وضغطها.',
    'فحص الخرطوم وفوهة القاذف.',
    'اختبار آلية البكرة.',
    'اختبار الانسدادات وتدفق المياه.',
    'تفقد تزييت الأجزاء المتحركة.',
    'التحقق من اللافتات والملصقات.',
  ];

  @override
  void initState() {
    super.initState();
    for (var step in steps) {
      checks[step] = false;
      notes[step] = TextEditingController();
    }
    _fetchTechnician();
    _fetchCompany();
  }

  Future<void> _fetchTechnician() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final data = await supabase.from('users').select('name').eq('id', user.id).maybeSingle();
      setState(() => technicianName = data?['name']);
    }
  }

  Future<void> _fetchCompany() async {
    final currentYear = DateTime.now().year;
    final data = await supabase
        .from('contract_companies')
        .select('company_name')
        .gte('contract_start_date', DateTime(currentYear, 1, 1).toIso8601String())
        .lte('contract_start_date', DateTime(currentYear, 12, 31).toIso8601String())
        .maybeSingle();
    setState(() => companyName = data?['company_name']);
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        currentDate = picked;
        nextDate = DateTime(picked.year + 1, picked.month, picked.day);
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || currentDate == null || technicianSignature.isEmpty || companySignature.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة كل الحقول وتوقيع النماذج')),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final stepsData = steps.map((s) => {
      'step': s,
      'checked': checks[s],
      'note': notes[s]!.text.trim(),
    }).toList();

    try {
      final insertData = {
        'tool_name': widget.toolName,
        'inspection_date': currentDate!.toIso8601String(),
        'next_inspection_date': nextDate!.toIso8601String(),
        'company_name': companyName,
        'company_rep': companyRep.text.trim(),
        'technician_name': technicianName,
        'steps': stepsData,
        'technician_signed': true,
        'company_signed': true,
        'other_notes': otherNotesController.text.trim(),
      };

      if (widget.taskType == 'دوري') {
        insertData['task_id'] = widget.taskId;
      }

      await supabase.from('hose_reel_reports').insert(insertData);

      if (widget.taskType == 'دوري') {
        await supabase.from('periodic_tasks').update({'status': 'done'}).eq('id', widget.taskId);
      }

      await supabase
          .from('safety_tools')
          .update({'next_maintenance_date': nextDate!.toIso8601String()})
          .eq('name', widget.toolName);

      final exportMaterials = stepsData
          .where((s) => s['note'] != null && s['note'].toString().isNotEmpty)
          .map((s) => {'toolName': widget.toolName, 'note': s['note']})
          .toList();

      if (otherNotesController.text.trim().isNotEmpty) {
        exportMaterials.add({
          'toolName': widget.toolName,
          'note': otherNotesController.text.trim(),
        });
      }

      if (!mounted) return;

      if (exportMaterials.isNotEmpty) {
        final existing = await supabase
            .from('export_requests')
            .select('id, tool_codes')
            .eq('created_by', user.id)
            .eq('is_approved', false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (existing != null) {
          final existingId = existing['id'];
          final List<dynamic> currentTools = existing['tool_codes'] ?? [];
          final updatedTools = [...currentTools, ...exportMaterials];

          await supabase.from('export_requests').update({
            'tool_codes': updatedTools,
            'usage_reason': updatedTools.map((m) => m['note']).join(' - '),
          }).eq('id', existingId);
        } else {
          await supabase.from('export_requests').insert({
            'tool_codes': exportMaterials,
            'created_by': user.id,
            'created_by_name': technicianName,
            'created_by_role': 'فني السلامة العامة',
            'usage_reason': exportMaterials.map((m) => m['note']).join(' - '),
            'action_taken': 'التقرير ${widget.taskType} - خرطوم الحريق',
            'is_approved': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التقرير')),
      );
    } catch (e) {
      print('🔥 Supabase error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    }
  }




  @override
  void dispose() {
    for (var controller in notes.values) {
      controller.dispose();
    }
    companyRep.dispose();
    otherNotesController.dispose();
    technicianSignature.dispose();
    companySignature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تقرير فحص خرطوم الحريق',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff00408b),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('تأكيد الخروج'),
                    content: const Text(
                      'هل أنت متأكد من رغبتك في مغادرة التقرير؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('نعم'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('لا'),
                      ),
                    ],
                  ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  title: Text('الأداة: ${widget.toolName}'),
                  subtitle:
                      currentDate != null
                          ? Text(
                            'تاريخ الفحص: ${DateFormat.yMd().format(currentDate!)}\nتاريخ الفحص القادم: ${DateFormat.yMd().format(nextDate!)}',
                          )
                          : const Text('لم يتم اختيار تاريخ'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'الإجراءات:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...steps.map(
                (step) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: checks[step],
                          onChanged: (v) => setState(() => checks[step] = v!),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(step, textAlign: TextAlign.right),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_note),
                          onPressed:
                              () => showDialog(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: Text('ملاحظات لـ $step'),
                                      content: TextFormField(
                                        controller: notes[step],
                                        maxLines: 4,
                                        textAlign: TextAlign.right,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('تم'),
                                        ),
                                      ],
                                    ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ملاحظات أخرى إن وجدت:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: otherNotesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'أدخل ملاحظات إضافية...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
    
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اسم الشركة المنفذة: ${companyName ?? '...'}'),
                      TextFormField(
                        controller: companyRep,
                        decoration: const InputDecoration(
                          labelText: 'اسم مندوب الشركة',
                        ),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      const Text('توقيع مندوب الشركة:'),
                      Signature(
                        controller: companySignature,
                        height: 100,
                        backgroundColor: Colors.grey[200]!,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اسم الفني: ${technicianName ?? '...'}'),
                      const Text('توقيع الفني:'),
                      Signature(
                        controller: technicianSignature,
                        height: 100,
                        backgroundColor: Colors.grey[200]!,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _submitReport,
                  icon: const Icon(Icons.check),
                  label: const Text('تقديم التقرير وإنهاء المهمة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00408b),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
