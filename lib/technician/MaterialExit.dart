import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _today = DateTime.now();
  final SignatureController technicianSignature = SignatureController(
    penStrokeWidth: 2,
  );
  final SignatureController managerSignature = SignatureController(
    penStrokeWidth: 2,
  );
  String materialType = 'مقتنيات شخصية';
  bool agree = false;

  List<Map<String, dynamic>> materials = [];
  String technicianName = '';
  String reason = '';
  bool isLoading = true;

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
            .eq('technician_id', user.id)
            .eq('is_approved', false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (response != null) {
      technicianName = response['technician_name'] ?? '';
      reason = response['reason'] ?? '';
      final toolName = response['tool_code'] ?? '';

      materials = [
        {'toolName': toolName, 'note': reason},
      ];
    }

    setState(() => isLoading = false);
  }

  Future<void> _selectReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _today,
      firstDate: _today,
      lastDate: _today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      _returnDateController.text = DateFormat.yMd().format(picked);
    }
  }

  Future<void> _submitAuthorization() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final signatureImage = await technicianSignature.toPngBytes();

    await supabase.from('material_exit_authorizations').insert({
      'technician_id': user.id,
      'technician_name': technicianName,
      'vehicle_number': _vehicleController.text.trim(),
      'vehicle_type': _vehicleTypeController.text.trim(),
      'return_date': DateFormat('yyyy-MM-dd').parse(_returnDateController.text),
      'material_type': materialType,
      'materials': materials,
      'signature': signatureImage,
      'agreed': true,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال تصريح إخراج المواد بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat.yMd().format(_today);
    final dayName = DateFormat.EEEE('ar').format(_today);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'تصريح اخراج مواد',
              style: TextStyle(color: Colors.white),
            ),
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
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'التاريخ: $todayFormatted',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'يسمح للسيد: $technicianName',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _vehicleController,
                      decoration: const InputDecoration(
                        labelText: 'الذي يقود مركبة رقم',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _vehicleTypeController,
                      decoration: const InputDecoration(labelText: 'نوع'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'بإخراج المواد المبينة أدناه:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...List.generate(materials.length, (i) {
                final material = materials[i];
                return ListTile(
                  leading: Text('- ${i + 1}'),
                  title: Text(material['toolName'] ?? ''),
                  subtitle: Text(material['note'] ?? ''),
                );
              }),
              const SizedBox(height: 16),
              const Text(
                'وذلك للأسباب التالية:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(reason, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
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
                      onChanged:
                          (value) => setState(() => materialType = value!),
                      decoration: const InputDecoration(
                        labelText: 'حيث أن المواد عبارة عن',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _returnDateController,
                      readOnly: true,
                      onTap: _selectReturnDate,
                      decoration: const InputDecoration(
                        labelText: 'تاريخ إعادة المواد',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'اسم الموظف: $technicianName',
                style: TextStyle(fontSize: 18),
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
