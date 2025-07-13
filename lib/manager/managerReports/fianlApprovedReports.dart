import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;

class FinalApprovedReportPage extends StatefulWidget {
  final Map<String, dynamic> report;
  const FinalApprovedReportPage({super.key, required this.report});

  @override
  State<FinalApprovedReportPage> createState() =>
      _FinalApprovedReportPageState();
}

class _FinalApprovedReportPageState extends State<FinalApprovedReportPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> edits = [];
  final workPlaces = ['هندسية', 'طبية', 'خدمات', 'مباني خارجية'];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadEdits();
  }

  Future<void> _loadEdits() async {
    final result = await supabase
        .from('head_edits')
        .select()
        .eq('task_id', widget.report['task_id'])
        .eq('task_type', widget.report['task_type']);
    setState(() {
      edits = List<Map<String, dynamic>>.from(result);
      loading = false;
    });
  }

  Widget buildStepComparison(Map<String, dynamic> step) {
    final headSteps = List<Map<String, dynamic>>.from(
      widget.report['steps'] ?? [],
    );
    final headStep = headSteps.firstWhere(
      (s) => s['step'] == step['step'],
      orElse: () => {},
    );

    final techChecked = step['checked'] == true;
    final headChecked = headStep['checked'] == true;
    final techNote = step['note'] ?? '';
    final headNote = headStep['note'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step['step'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('✅ الفني: '),
                Icon(
                  techChecked ? Icons.check_circle : Icons.cancel,
                  color: techChecked ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(techNote)),
              ],
            ),
            Row(
              children: [
                const Text('🛠 الرئيس: '),
                Icon(
                  headChecked ? Icons.check_circle : Icons.cancel,
                  color: headChecked ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headNote,
                    style: TextStyle(
                      color:
                          headNote.trim() != techNote.trim()
                              ? Colors.blueAccent
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSignature(String label, String? base64) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        base64 != null
            ? Image.memory(base64Decode(base64), height: 100)
            : const Text('لا يوجد توقيع'),
      ],
    );
  }

  Widget buildEditSection() {
    if (edits.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'تعديلات رئيس الشعبة:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...edits.map(
          (e) => ListTile(
            title: Text(e['field_name'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ الفني: ${e['technician_value']}'),
                Text(
                  '🛠 الرئيس: ${e['head_value']}',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = List<Map<String, dynamic>>.from(
      widget.report['technician_steps'] ?? widget.report['steps'] ?? [],
    );
    final inspectionDate =
        widget.report['inspection_date'] != null
            ? DateFormat.yMMMd().format(
              DateTime.parse(widget.report['inspection_date']),
            )
            : 'غير معروف';
    final nextDate =
        widget.report['next_inspection_date'] != null
            ? DateFormat.yMMMd().format(
              DateTime.parse(widget.report['next_inspection_date']),
            )
            : 'غير معروف';
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'تفاصيل التقرير المعتمد',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفني: ${widget.report['technician_name'] ?? '---'}',
                      ),
                      Text(
                        'رئيس الشعبة: ${widget.report['head_name'] ?? '---'}',
                      ),
                      Text(
                        'اسم مندوب الشركة: ${widget.report['company_rep'] ?? '---'}',
                      ),
                      Text(
                        'ملاحظات إضافية: ${widget.report['other_notes'] ?? '---'}',
                      ),
                      Text('تاريخ الفحص: $inspectionDate'),
                      Text('الفحص القادم: $nextDate'),
                      const SizedBox(height: 16),
                      const Text(
                        'تفاصيل الخطوات:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...steps.map(buildStepComparison).toList(),
                      const SizedBox(height: 16),
                      buildSignature(
                        'توقيع الفني',
                        widget.report['technician_signature'],
                      ),
                      const SizedBox(height: 16),
                      buildSignature(
                        'توقيع مندوب الشركة',
                        widget.report['company_signature'],
                      ),
                      const SizedBox(height: 16),
                      buildSignature(
                        'توقيع رئيس الشعبة',
                        widget.report['head_signature'],
                      ),
                      const SizedBox(height: 16),
                      buildEditSection(),
                    ],
                  ),
                ),
      ),
    );
  }
}
