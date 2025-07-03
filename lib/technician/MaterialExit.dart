import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:ui' as ui;

class MaterialExitAuthorizationPage extends StatefulWidget {
  const MaterialExitAuthorizationPage({super.key});

  @override
  State<MaterialExitAuthorizationPage> createState() =>
      _MaterialExitAuthorizationPageState();
}

class _MaterialExitAuthorizationPageState
    extends State<MaterialExitAuthorizationPage> {
  final _vehicleController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _returnDateController = TextEditingController();
  final SignatureController technicianSignature = SignatureController(
    penStrokeWidth: 2,
  );
  DateTime? selectedReturnDate;

  String materialType = 'مقتنيات شخصية';
  String technicianName = '';
  bool agree = false;
  bool isLoading = true;
  String? requestId;

  List<Map<String, dynamic>> materials = [];

  @override
  void initState() {
    super.initState();
    _loadExportRequest();
  }

  Future<void> _loadExportRequest() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response =
        await supabase
            .from('export_requests')
            .select()
            .eq('created_by', user.id)
            .eq('is_approved', false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (response != null) {
      requestId = response['id'];
      technicianName = response['created_by_name'] ?? '';

      final List<dynamic>? toolList = response['tool_codes'];
      if (toolList != null) {
        final uniqueMap = <String, Map<String, dynamic>>{};
        for (final item in toolList) {
          final toolName = item['toolName'];
          if (toolName != null && toolName is String && toolName.isNotEmpty) {
            uniqueMap[toolName] = {
              'toolName': toolName,
              'note': item['note'] ?? '',
            };
          }
        }
        materials = uniqueMap.values.toList();
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> _selectReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedReturnDate = picked;
        _returnDateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  Future<void> _submitAuthorization() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    if (technicianSignature.isEmpty ||
        _returnDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول وتوقيع التصريح')),
      );
      return;
    }
    if (materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة أداة واحدة على الأقل')),
      );
      return;
    }

    try {
      final signatureBytes = await technicianSignature.toPngBytes();
      final signatureBase64 = base64Encode(signatureBytes!);

      final DateTime? parsedReturnDate = selectedReturnDate;
      if (parsedReturnDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار تاريخ الإرجاع')),
        );
        return;
      }

      final payload = {
        'vehicle_owner': technicianName,
        'vehicle_number': _vehicleController.text.trim(),
        'vehicle_type': _vehicleTypeController.text.trim(),
        'return_date': parsedReturnDate.toIso8601String(), // ✅ أهم تعديل هنا
        'material_type': materialType,
        'technician_signature': signatureBase64,
        'tool_codes': materials,
        'usage_reason': materials.map((m) => m['note']).join(' - '),
      };

      if (requestId != null) {
        await supabase
            .from('export_requests')
            .update({...payload, 'is_submitted': true})
            .eq('id', requestId!);
      } else {
        await supabase.from('export_requests').insert({
          ...payload,
          'created_by': user.id,
          'created_by_name': technicianName,
          'created_by_role': 'فني السلامة العامة',
          'is_approved': false,
          'is_submitted': true, // ✅ تمت الإرسال فعليًا
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التقرير بنجاح، بانتظار موافقة المدير'),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error during submit: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
    }
  }

  void _addNewMaterial() {
    setState(() {
      materials.add({'toolName': '', 'note': ''});
    });
  }

  void _removeMaterial(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: const Text('هل أنت متأكد أنك تريد حذف هذه الأداة؟'),
              actions: [
                TextButton(
                  child: const Text('حذف'),
                  onPressed: () => Navigator.pop(context, true),
                ),
                TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
    );

    if (confirm == true) {
      setState(() => materials.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat.yMd().format(DateTime.now());
    final dayName = DateFormat.EEEE('ar').format(DateTime.now());

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تصريح اخراج مواد',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'جامعة العلوم والتكنولوجيا الاردنية / دائرة السلامة والصحة المهنية والبيئية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'اليوم: $dayName',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'التاريخ: $todayFormatted',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'يسمح للسيد: $technicianName',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vehicleController,
                decoration: const InputDecoration(labelText: 'رقم المركبة'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(labelText: 'نوع المركبة'),
              ),
              const SizedBox(height: 16),
              const Text(
                'بإخراج المواد المبينة أدناه:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...materials.asMap().entries.map((entry) {
                final index = entry.key;
                final material = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: material['toolName'],
                          decoration: const InputDecoration(
                            labelText: 'اسم الأداة',
                          ),
                          onChanged:
                              (val) => materials[index]['toolName'] = val,
                        ),
                        TextFormField(
                          initialValue: material['note'],
                          decoration: const InputDecoration(labelText: 'السبب'),
                          onChanged: (val) => materials[index]['note'] = val,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => _removeMaterial(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _addNewMaterial,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة أداة جديدة'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: materialType,
                items: const [
                  DropdownMenuItem(
                    value: 'مقتنيات شخصية',
                    child: Text('مقتنيات شخصية'),
                  ),
                  DropdownMenuItem(
                    value: 'مقتنيات جامعية',
                    child: Text('مقتنيات جامعية'),
                  ),
                ],
                onChanged: (value) => setState(() => materialType = value!),
                decoration: const InputDecoration(labelText: 'نوع المواد'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _returnDateController,
                readOnly: true,
                onTap: _selectReturnDate,
                decoration: const InputDecoration(
                  labelText: 'تاريخ إعادة المواد',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اسم الموظف: $technicianName',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text('توقيعه:'),
              Signature(
                controller: technicianSignature,
                height: 100,
                backgroundColor: Colors.grey[200]!,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: agree,
                onChanged: (v) => setState(() => agree = v ?? false),
                title: const Text(
                  'على أن يقوم بإعادتها فور انتهاء العمل المطلوب',
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: agree ? _submitAuthorization : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00408b),
                  ),
                  child: const Text(
                    'إرسال التصريح',
                    style: TextStyle(color: Colors.white),
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
