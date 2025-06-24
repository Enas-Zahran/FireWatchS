import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

class FireHydrantReportPage extends StatefulWidget {
  final String taskId;
  final String toolName;

  const FireHydrantReportPage({super.key, required this.taskId, required this.toolName});

  @override
  State<FireHydrantReportPage> createState() => _FireHydrantReportPageState();
}

class _FireHydrantReportPageState extends State<FireHydrantReportPage> {
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

  final List<String> steps = [
    'تفقد الصمام الرئيسي والصمامات الفرعية .',
    'نفقد جسم الصمام من التأكل (الصداء) .',
    'تفقد الصمام بعدم وجود تسريبات للماء منه.',
    'تفقد نظافة الصمام والطلاء .',
    'التحقق من وصول الماء وضغطة .',
    'تفقد أي عوائق قد تعيق عمل الفوهة.',
    'التحقق من وجود أغطية متشققة أو مفقودة.',
    'تفقد لاقط الخرطوم المغذي لسيارات الدفاع المدني'
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء تعبئة كل الحقول وتوقيع النماذج')));
      return;
    }

    await supabase.from('fire_hydrant_reports').insert({
      'task_id': widget.taskId,
      'tool_name': widget.toolName,
      'inspection_date': currentDate!.toIso8601String(),
      'next_inspection_date': nextDate!.toIso8601String(),
      'company_name': companyName,
      'company_rep': companyRep.text.trim(),
      'technician_name': technicianName,
      'steps': steps.map((s) => {
        'step': s,
        'checked': checks[s],
        'note': notes[s]!.text.trim(),
      }).toList(),
      'technician_signed': true,
      'company_signed': true,
    });

    await supabase.from('periodic_tasks').update({'status': 'done'}).eq('id', widget.taskId);
    await supabase.from('safety_tools').update({'next_maintenance_date': nextDate!.toIso8601String()}).eq('name', widget.toolName);
    await supabase.from('export_requests').insert({
      'tool_code': widget.toolName,
      'reason': 'حسب تقرير فحص دوري - ${notes.entries.where((e) => e.value.text.isNotEmpty).map((e) => e.value.text).join(', ')}',
      'created_by': supabase.auth.currentUser!.id,
      'created_by_role': 'فني السلامة العامة'
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التقرير وإرسال الأداة للإخراج')));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقرير فحص صنبور الحريق', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Directionality(
                  textDirection: TextDirection.rtl,
                  child: AlertDialog(
                    title: const Text('تأكيد الخروج'),
                    content: const Text('هل أنت متأكد من رغبتك في مغادرة التقرير؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('لا'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const Text('نعم'),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    title: Text('الأداة: ${widget.toolName}'),
                    subtitle: currentDate != null
                        ? Text('تاريخ الفحص: ${DateFormat.yMd().format(currentDate!)}\nتاريخ الفحص القادم: ${DateFormat.yMd().format(nextDate!)}')
                        : const Text('لم يتم اختيار تاريخ'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('الإجراءات:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...steps.map((step) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(value: checks[step], onChanged: (v) => setState(() => checks[step] = v!)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(step, textAlign: TextAlign.right)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_note),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('ملاحظات لـ $step'),
                              content: TextFormField(controller: notes[step], maxLines: 4, textAlign: TextAlign.right),
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تم'))],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('اسم الشركة المنفذة: ${companyName ?? '...'}'),
                        TextFormField(
                          controller: companyRep,
                          decoration: const InputDecoration(labelText: 'اسم مندوب الشركة'),
                          validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 12),
                        const Text('توقيع مندوب الشركة:'),
                        Signature(controller: companySignature, height: 100, backgroundColor: Colors.grey[200]!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('اسم الفني: ${technicianName ?? '...'}'),
                        const Text('توقيع الفني:'),
                        Signature(controller: technicianSignature, height: 100, backgroundColor: Colors.grey[200]!),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
