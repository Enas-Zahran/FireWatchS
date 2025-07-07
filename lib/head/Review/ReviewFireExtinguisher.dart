import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

class FireExtinguisherHeadReviewPage extends StatefulWidget {
  final String taskId;
  final String toolName;
  final String headName;
  final String taskType; // دوري - علاجي - طارئ

  const FireExtinguisherHeadReviewPage({
    super.key,
    required this.taskId,
    required this.toolName,
    required this.headName,
    required this.taskType,
  });

  @override
  State<FireExtinguisherHeadReviewPage> createState() =>
      _FireExtinguisherHeadReviewPageState();
}

class _FireExtinguisherHeadReviewPageState
    extends State<FireExtinguisherHeadReviewPage> {
  final supabase = Supabase.instance.client;
  final SignatureController headSignature = SignatureController(
    penStrokeWidth: 2,
  );
  DateTime? inspectionDate;
  DateTime? nextInspectionDate;
  List<String> steps = [
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
  Map<String, bool> checks = {};
  Map<String, TextEditingController> notes = {};
  TextEditingController companyRep = TextEditingController();
  TextEditingController otherNotes = TextEditingController();
  String? companyName, technicianName;
  bool isApproved = false;
  bool loading = true;
  String get table =>
      widget.taskType == 'دوري'
          ? 'fire_extinguisher_reports'
          : 'fire_extinguisher_correctiveemergency';

  @override
  void initState() {
    super.initState();
    for (final s in steps) {
      checks[s] = false;
      notes[s] = TextEditingController();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final data =
        await supabase
            .from(table)
            .select()
            .eq('task_id', widget.taskId)
            .maybeSingle();
    if (data == null) return;

    inspectionDate = DateTime.tryParse(data['inspection_date'] ?? '');
    nextInspectionDate = DateTime.tryParse(data['next_inspection_date'] ?? '');
    companyName = data['company_name'];
    companyRep.text = data['company_rep'] ?? '';
    technicianName = data['technician_name'];
    otherNotes.text = data['other_notes'] ?? '';
    isApproved = data['head_approved'] == true;

    if (data['steps'] != null) {
      for (final step in data['steps']) {
        final label = step['step'];
        if (steps.contains(label)) {
          checks[label] = step['checked'] ?? false;
          notes[label]?.text = step['note'] ?? '';
        }
      }
    }

    setState(() => loading = false);
  }

  Future<void> _saveEdits() async {
    if (headSignature.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى توقيع رئيس الشعبة قبل الاعتماد.')),
      );
      return;
    }

    final signatureBytes = await headSignature.toPngBytes();
    final signatureBase64 = base64Encode(signatureBytes!);

    final editedSteps =
        steps.map((step) {
          return {
            'step': step,
            'checked': checks[step] ?? false,
            'note': notes[step]?.text ?? '',
          };
        }).toList();

    final original =
        await supabase
            .from(table)
            .select()
            .eq('task_id', widget.taskId)
            .maybeSingle();

    final updates = {
      'steps': editedSteps,
      'other_notes': otherNotes.text.trim(),
      'company_rep': companyRep.text.trim(),
      'head_name': widget.headName,
      'head_signature': signatureBase64,
      'head_approved': true,
    };

    Future<void> saveEdit(
      String fieldName,
      String? originalValue,
      String? newValue,
    ) async {
      if ((originalValue ?? '').trim() != (newValue ?? '').trim()) {
        await supabase.from('head_edits').insert({
          'task_id': widget.taskId,
          'field_name': fieldName,
          'technician_value': originalValue ?? '',
          'head_value': newValue ?? '',
          'head_name': widget.headName,
          'head_id': supabase.auth.currentUser?.id,
        });
      }
    }

    await saveEdit(
      'company_rep',
      original?['company_rep'],
      companyRep.text.trim(),
    );
    await saveEdit(
      'other_notes',
      original?['other_notes'],
      otherNotes.text.trim(),
    );

    if (original != null &&
        original['steps'] != null &&
        original['steps'] is List) {
      for (final step in editedSteps) {
        final label = step['step'];
        final originalStep = (original['steps'] as List).firstWhere(
          (s) => s['step'] == label,
          orElse: () => null,
        );

        if (originalStep != null) {
          final bool oldChecked = originalStep['checked'] == true;
          final bool newChecked = step['checked'] == true;

          if (oldChecked != newChecked) {
            await saveEdit(
              'الخطوة: $label - checked',
              oldChecked.toString(),
              newChecked.toString(),
            );
          }

          final oldNote = (originalStep['note'] ?? '').toString();
          final newNote = (step['note'] ?? '').toString();

          if (oldNote.trim() != newNote.trim()) {
            await saveEdit('الخطوة: $label - note', oldNote, newNote);
          }
        }
      }
    }

    await supabase.from(table).update(updates).eq('task_id', widget.taskId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم اعتماد التقرير.')));
    setState(() => isApproved = true);
  }

  @override
  void dispose() {
    for (var c in notes.values) {
      c.dispose();
    }
    headSignature.dispose();
    companyRep.dispose();
    otherNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'مراجعة تقرير - ${widget.toolName}',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: ListTile(
                          title: Text(
                            'تاريخ الفحص: ${inspectionDate != null ? DateFormat.yMd().format(inspectionDate!) : 'غير محدد'}',
                          ),
                          subtitle: Text(
                            'الفحص القادم: ${nextInspectionDate != null ? DateFormat.yMd().format(nextInspectionDate!) : 'غير محدد'}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'الخطوات:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...steps.map(
                        (step) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Checkbox(
                              value: checks[step],
                              onChanged:
                                  isApproved
                                      ? null
                                      : (v) => setState(
                                        () => checks[step] = v ?? false,
                                      ),
                            ),
                            title: Text(step),
                            subtitle: TextFormField(
                              controller: notes[step],
                              enabled: !isApproved,
                              decoration: const InputDecoration(
                                hintText: 'ملاحظات',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ملاحظات إضافية:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: otherNotes,
                        maxLines: 4,
                        enabled: !isApproved,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الشركة: ${companyName ?? '---'}'),
                              TextFormField(
                                controller: companyRep,
                                enabled: !isApproved,
                                decoration: const InputDecoration(
                                  labelText: 'اسم مندوب الشركة',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('الفني: ${technicianName ?? '---'}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('توقيع رئيس الشعبة:'),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(border: Border.all()),
                        child: Signature(
                          controller: headSignature,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isApproved)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _saveEdits,
                            icon: const Icon(Icons.check),
                            label: const Text('اعتماد التقرير'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff00408b),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      if (isApproved)
                        const Center(
                          child: Text(
                            'تم اعتماد هذا التقرير',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
