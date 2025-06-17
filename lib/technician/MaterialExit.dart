import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaterialExitAuthorizationPage extends StatefulWidget {
  final List<Map<String, dynamic>> materials; // [{toolName: ..., note: ...}]
  final String technicianName;

  const MaterialExitAuthorizationPage({super.key, required this.materials, required this.technicianName});

  @override
  State<MaterialExitAuthorizationPage> createState() => _MaterialExitAuthorizationPageState();
}

class _MaterialExitAuthorizationPageState extends State<MaterialExitAuthorizationPage> {
  final _vehicleController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _today = DateTime.now();
  final SignatureController technicianSignature = SignatureController(penStrokeWidth: 2);
  final SignatureController managerSignature = SignatureController(penStrokeWidth: 2);
  String materialType = 'مقتنيات شخصية';
  bool agree = false;

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
    final materials = widget.materials
        .map((m) => {
              'toolName': m['toolName'],
              'note': m['note'],
            })
        .toList();

    await supabase.from('material_exit_authorizations').insert({
      'technician_id': user.id,
      'technician_name': widget.technicianName,
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تصريح اخراج مواد'),
          backgroundColor: const Color(0xff00408b),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'جامعة العلوم والتكنولوجيا الاردنية / دائرة السلامة والصحة المهنية والبيئية',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('اليوم: $dayName')),
                  Expanded(child: Text('التاريخ: $todayFormatted')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('يسمح للسيد: ${widget.technicianName}')),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _vehicleController, decoration: const InputDecoration(labelText: 'الذي يقود مركبة رقم'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _vehicleTypeController, decoration: const InputDecoration(labelText: 'نوع'))),
                ],
              ),
              const SizedBox(height: 16),
              const Text('بإخراج المواد المبينة أدناه:'),
              const SizedBox(height: 8),
              ...List.generate(widget.materials.length, (i) {
                final material = widget.materials[i];
                return ListTile(
                  leading: Text('- ${i + 1}'),
                  title: Text(material['toolName'] ?? ''),
                  subtitle: Text(material['note'] ?? ''),
                  onTap: () {},
                );
              }),
              const SizedBox(height: 16),
              const Text('وذلك للأسباب التالية:'),
              const SizedBox(height: 8),
              ...List.generate(widget.materials.length, (i) {
                final note = widget.materials[i]['note']?.trim();
                return (note != null && note.isNotEmpty)
                    ? Text('- ${i + 1}: $note')
                    : const SizedBox.shrink();
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: materialType,
                      items: const [
                        DropdownMenuItem(value: 'مقتنيات شخصية', child: Text('مقتنيات شخصية')),
                        DropdownMenuItem(value: 'مقتنيات جامعية', child: Text('مقتنيات جامعية')),
                      ],
                      onChanged: (value) => setState(() => materialType = value!),
                      decoration: const InputDecoration(labelText: 'حيث أن المواد عبارة عن'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _returnDateController,
                      readOnly: true,
                      onTap: _selectReturnDate,
                      decoration: const InputDecoration(labelText: 'تاريخ إعادة المواد'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('اسم الموظف: ${widget.technicianName}'),
              const SizedBox(height: 8),
              const Text('توقيعه:'),
              Signature(controller: technicianSignature, height: 100, backgroundColor: Colors.grey[200]!),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: agree,
                onChanged: (v) => setState(() => agree = v ?? false),
                title: const Text('على أن يقوم بإعادتها فور انتهاء العمل المطلوب'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: agree ? _submitAuthorization : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00408b)),
                child: const Text('إرسال التصريح'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
