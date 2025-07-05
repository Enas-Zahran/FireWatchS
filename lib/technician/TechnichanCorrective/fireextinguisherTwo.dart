import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class FireExtinguisherCorrectiveEmergency extends StatefulWidget {
  final String taskId;
  final String toolName;
  final String taskType; // 'علاجي' أو 'طارئ'
  final bool isReadonly;

  const FireExtinguisherCorrectiveEmergency({
    super.key,
    required this.taskId,
    required this.toolName,
    required this.taskType,
    this.isReadonly = false,
  });

  @override
  State<FireExtinguisherCorrectiveEmergency> createState() =>
      _FireExtinguisherCorrectiveEmergencyState();
}

class _FireExtinguisherCorrectiveEmergencyState
    extends State<FireExtinguisherCorrectiveEmergency> {
  final supabase = Supabase.instance.client;
  DateTime? currentDate;
  DateTime? nextDate;
  Map<String, bool> checks = {};
  Map<String, TextEditingController> notes = {};
  final SignatureController technicianSignature = SignatureController(
    penStrokeWidth: 2,
  );
  final SignatureController companySignature = SignatureController(
    penStrokeWidth: 2,
  );
  final _formKey = GlobalKey<FormState>();
  final TextEditingController companyRep = TextEditingController();
  final TextEditingController otherNotesController = TextEditingController();
  String? companyName;
  String? technicianName;

  final List<String> steps = [
    'الطلاء لجسم الطفاية',
    'خلو الجسم من الصدأ',
    'صحة الكرت الموجود على جسم الطفاية',
    'تفقد خرطوم الطفاية',
    'تفقد مقبض الطفاية',
    'تفقد ساعة الضغط',
    'تفقد قاذف الطفاية',
    'تفقد مسمار الأمان',
    'وزن الطفاية',
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
      final data =
          await supabase
              .from('users')
              .select('name')
              .eq('id', user.id)
              .maybeSingle();
      setState(() => technicianName = data?['name']);
    }
  }

  Future<void> _fetchCompany() async {
    final currentYear = DateTime.now().year;
    final data =
        await supabase
            .from('contract_companies')
            .select('company_name')
            .gte(
              'contract_start_date',
              DateTime(currentYear, 1, 1).toIso8601String(),
            )
            .lte(
              'contract_start_date',
              DateTime(currentYear, 12, 31).toIso8601String(),
            )
            .maybeSingle();
    setState(() => companyName = data?['company_name']);
  }

  void _pickDate() async {
    if (widget.isReadonly) return;
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
    if (!_formKey.currentState!.validate() ||
        currentDate == null ||
        technicianSignature.isEmpty ||
        companySignature.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة كل الحقول وتوقيع النماذج')),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final stepsData =
        steps
            .map(
              (s) => {
                'step': s,
                'checked': checks[s],
                'note': notes[s]!.text.trim(),
              },
            )
            .toList();

    final writtenNotes =
        stepsData
            .where((s) => s['note'] != null && s['note'].toString().isNotEmpty)
            .map((s) => {'toolName': widget.toolName, 'note': s['note']})
            .toList();

    if (otherNotesController.text.trim().isNotEmpty) {
      writtenNotes.add({
        'toolName': widget.toolName,
        'note': otherNotesController.text.trim(),
      });
    }

    try {
      await supabase.from('fire_extinguisher_correctiveemergency').insert({
        'task_id': widget.taskId,
        'task_type': widget.taskType,
        'tool_name': widget.toolName,
        'inspection_date': currentDate!.toIso8601String(),
        'next_inspection_date': nextDate!.toIso8601String(),
        'company_name': companyName,
        'company_rep': companyRep.text.trim(),
        'technician_name': technicianName,
        'steps': stepsData,
        'other_notes': otherNotesController.text.trim(),
        'technician_signed': true,
        'company_signed': true,
      });

      await supabase
          .from('safety_tools')
          .update({
            'last_maintenance_date': currentDate!.toIso8601String(),
            'next_maintenance_date': nextDate!.toIso8601String(),
          })
          .eq('name', widget.toolName);

      if (widget.taskType == 'علاجي') {
        await supabase
            .from('corrective_tasks')
            .update({'status': 'done'})
            .eq('id', widget.taskId);
      } else if (widget.taskType == 'طارئ') {
        await supabase
            .from('emergency_tasks')
            .update({'status': 'done'})
            .eq('id', widget.taskId);
      }

      if (writtenNotes.isNotEmpty && context.mounted) {
        final reasonText = writtenNotes.map((m) => m['note']).join(' - ');

        final existing =
            await supabase
                .from('export_requests')
                .select('id, tool_codes')
                .eq('created_by', user.id)
                .filter('is_approved', 'is', null)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

        if (existing != null) {
          final existingId = existing['id'];
          final List<dynamic> currentTools = existing['tool_codes'] ?? [];
          final updatedTools = [...currentTools, ...writtenNotes];

          await supabase
              .from('export_requests')
              .update({
                'tool_codes': updatedTools,
                'usage_reason': updatedTools.map((m) => m['note']).join(' - '),
              })
              .eq('id', existingId);
        } else {
          await supabase.from('export_requests').insert({
            'tool_codes': writtenNotes,
            'created_by': user.id,
            'created_by_role': 'فني السلامة العامة',
            'created_by_name': technicianName,
            'usage_reason': reasonText,
            'action_taken': 'تقرير ${widget.taskType} - طفاية الحريق',
            'is_approved': null,
            'is_submitted': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ التقرير')));
    } catch (e) {
      print('🔥 Supabase error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
    }
  }

  @override
  void dispose() {
    for (var controller in notes.values) {
      controller.dispose();
    }
    otherNotesController.dispose();
    companyRep.dispose();
    technicianSignature.dispose();
    companySignature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تقرير فحص طفاية حريق',
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
                    (context) => Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: AlertDialog(
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
                    trailing:
                        widget.isReadonly
                            ? null
                            : IconButton(
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
                            onChanged:
                                widget.isReadonly
                                    ? null
                                    : (v) => setState(() => checks[step] = v!),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(step, textAlign: TextAlign.right),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_note),
                            onPressed:
                                widget.isReadonly
                                    ? null
                                    : () => showDialog(
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
                                                    () =>
                                                        Navigator.pop(context),
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
                const Text(
                  'ملاحظات أخرى إن وجدت:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: otherNotesController,
                  maxLines: 4,
                  enabled: !widget.isReadonly,
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
                          enabled: !widget.isReadonly,
                          decoration: const InputDecoration(
                            labelText: 'اسم مندوب الشركة',
                          ),
                          validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 12),
                        const Text('توقيع مندوب الشركة:'),
                        AbsorbPointer(
                          absorbing: widget.isReadonly,
                          child: Signature(
                            controller: companySignature,
                            height: 100,
                            backgroundColor: Colors.grey[200]!,
                          ),
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
                        AbsorbPointer(
                          absorbing: widget.isReadonly,
                          child: Signature(
                            controller: technicianSignature,
                            height: 100,
                            backgroundColor: Colors.grey[200]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!widget.isReadonly)
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
      ),
    );
  }
}
