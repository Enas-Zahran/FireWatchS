import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

class HoseReelHeadReviewPage extends StatefulWidget {
  final String taskId;
  final String toolName;
  final String taskType; // دوري - علاجي - طارئ
  final String headName;

  const HoseReelHeadReviewPage({
    super.key,
    required this.taskId,
    required this.toolName,
    required this.taskType,
    required this.headName,
  });

  @override
  State<HoseReelHeadReviewPage> createState() => _HoseReelHeadReviewPageState();
}

class _HoseReelHeadReviewPageState extends State<HoseReelHeadReviewPage> {
  final supabase = Supabase.instance.client;
  final SignatureController headSignature = SignatureController(
    penStrokeWidth: 2,
  );
  DateTime? currentDate;
  DateTime? nextDate;
  String? companyName, technicianName;
  final TextEditingController companyRep = TextEditingController();
  final TextEditingController otherNotes = TextEditingController();

  final List<String> steps = [
    'الفحص الأولي لجميع الأجزاء من التأكل والصداء.',
    'التحقق من وصول المياه وضغطها.',
    'فحص الخرطوم وفوهة القاذف.',
    'اختبار آلية البكرة.',
    'اختبار الانسدادات وتدفق المياه.',
    'تفقد تزييت الأجزاء المتحركة.',
    'التحقق من اللافتات والملصقات.',
  ];

  Map<String, bool> checks = {};
  Map<String, TextEditingController> notes = {};

  bool isApproved = false;
  bool loading = true;
  Map<String, dynamic>? reportData;
  String? technicianSignatureBase64;
  String? companySignatureBase64;

  @override
  void initState() {
    super.initState();
    for (var s in steps) {
      checks[s] = false;
      notes[s] = TextEditingController();
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final data =
        await supabase
            .from('hose_reel_reports')
            .select()
            .eq('task_id', widget.taskId)
            .maybeSingle();
    reportData = data;

    if (data == null) return;

    currentDate = DateTime.tryParse(data['inspection_date'] ?? '');
    nextDate = DateTime.tryParse(data['next_inspection_date'] ?? '');
    companyName = data['company_name'];
    companyRep.text = data['company_rep'] ?? '';
    technicianName = data['technician_name'];
    technicianSignatureBase64 = data['technician_signature'];
    companySignatureBase64 = data['company_signature'];

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

    // 🔍 Fetch original report
    final original =
        await supabase
            .from('hose_reel_reports')
            .select()
            .eq('task_id', widget.taskId)
            .maybeSingle();

    final updates = {
      'steps': editedSteps,
      'other_notes': otherNotes.text.trim(),
      'company_rep': companyRep.text.trim(),
      'head_approved': true,
      'head_name': widget.headName,
      'head_signature': signatureBase64,
    };

    // 🧠 Save edit helper
    Future<void> saveEdit(
      String fieldName,
      String? oldVal,
      String? newVal,
    ) async {
      if ((oldVal ?? '').trim() != (newVal ?? '').trim()) {
        await supabase.from('head_edits').insert({
          'task_id': widget.taskId,
          'task_type': widget.taskType,
          'field_name': fieldName,
          'technician_value': oldVal ?? '',
          'head_value': newVal ?? '',
          'head_name': widget.headName,
          'head_id': supabase.auth.currentUser?.id,
        });
      }
    }

    // 📝 Save simple fields
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

    // 🧾 Compare steps
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

    // ✅ Update final report
    await supabase
        .from('hose_reel_reports')
        .update(updates)
        .eq('task_id', widget.taskId);

    if (mounted) {
      setState(() => isApproved = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم اعتماد التقرير بنجاح')));
    }
  }

  @override
  void dispose() {
    for (var c in notes.values) {
      c.dispose();
    }
    companyRep.dispose();
    otherNotes.dispose();
    headSignature.dispose();
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
                            'تاريخ الفحص: ${currentDate != null ? DateFormat.yMd().format(currentDate!) : '---'}',
                          ),
                          subtitle: Text(
                            'تاريخ الفحص القادم: ${nextDate != null ? DateFormat.yMd().format(nextDate!) : '---'}',
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
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: checks[step],
                                      onChanged:
                                          isApproved
                                              ? null
                                              : (val) => setState(
                                                () =>
                                                    checks[step] = val ?? false,
                                              ),
                                    ),
                                    Expanded(child: Text(step)),
                                  ],
                                ),
                                TextFormField(
                                  controller: notes[step],
                                  enabled: !isApproved,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'ملاحظات',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ملاحظات إضافية:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: otherNotes,
                        enabled: !isApproved,
                        maxLines: 3,
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
                              const Text('توقيع مندوب الشركة:'),
                              if (companySignatureBase64 != null)
                                Image.memory(
                                  base64Decode(companySignatureBase64!),
                                  height: 100,
                                  fit: BoxFit.contain,
                                )
                              else
                                const Text('لا يوجد توقيع'),

                              const SizedBox(height: 8),
                              Text('الفني: ${technicianName ?? '---'}'),
                              const Text('توقيع الفني:'),
                              if (technicianSignatureBase64 != null)
                                Image.memory(
                                  base64Decode(technicianSignatureBase64!),
                                  height: 100,
                                  fit: BoxFit.contain,
                                )
                              else
                                const Text('لا يوجد توقيع'),
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
                      const SizedBox(height: 20),
                      if (!isApproved)
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('اعتماد التقرير'),
                            onPressed: _saveEdits,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff00408b),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      if (isApproved)
                        const Center(
                          child: Text(
                            'تم اعتماد هذا التقرير ✅',
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
