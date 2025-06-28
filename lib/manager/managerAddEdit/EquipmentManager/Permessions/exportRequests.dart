import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/Permessions/exportDetails.dart';
class ExportRequestMaterialsPage extends StatefulWidget {
  final String requestId;
  final String technicianName;

  const ExportRequestMaterialsPage({
    super.key,
    required this.requestId,
    required this.technicianName,
  });

  @override
  State<ExportRequestMaterialsPage> createState() => _ExportRequestMaterialsPageState();
}

class _ExportRequestMaterialsPageState extends State<ExportRequestMaterialsPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? request;
  final SignatureController managerSignature = SignatureController(penStrokeWidth: 2);

  final _vehicleOwnerController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _returnDateController = TextEditingController();
  String materialType = 'مقتنيات شخصية';
  DateTime? returnDate;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequest();
  }

  Future<void> _fetchRequest() async {
    final data = await supabase
        .from('export_requests')
        .select()
        .eq('id', widget.requestId)
        .maybeSingle();

    if (data != null) {
      setState(() {
        request = data;
        _vehicleOwnerController.text = data['vehicle_owner'] ?? '';
        _vehicleNumberController.text = data['vehicle_number'] ?? '';
        _vehicleTypeController.text = data['vehicle_type'] ?? '';
if (data['return_date'] != null) {
  returnDate = DateTime.tryParse(data['return_date']);
  _returnDateController.text = DateFormat.yMd().format(returnDate!);
}
        materialType = data['material_type'] ?? 'مقتنيات شخصية';
        loading = false;
      });
    }
  }

  Future<void> _pickReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        returnDate = picked;
        _returnDateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  Future<void> _approveRequest() async {
    if (managerSignature.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب توقيع المدير لاعتماد الطلب')),
      );
      return;
    }

    final signatureBytes = await managerSignature.toPngBytes();

    await supabase
        .from('export_requests')
        .update({
          'vehicle_owner': _vehicleOwnerController.text.trim(),
          'vehicle_number': _vehicleNumberController.text.trim(),
          'vehicle_type': _vehicleTypeController.text.trim(),
        'return_date': (returnDate ?? DateTime.tryParse(request?['return_date'] ?? '') ?? DateTime.now()).toIso8601String(),

          'material_type': materialType,
          'status': 'approved',
          'manager_signature': signatureBytes,
        })
        .eq('id', widget.requestId);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم اعتماد الطلب بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Text('مراجعة طلب إخراج المواد', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      body: loading
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (request != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExportRequestDetailsPage(request: request!),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xff00408b)),
                  const SizedBox(width: 8),
                  Text(
                    'الفني: ${widget.technicianName}',
                    style: const TextStyle(
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('المواد المطلوبة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(request?['tool_codes'] as List<dynamic>?)?.map((item) {
              return ListTile(
                leading: const Icon(Icons.build),
                title: Text(item['toolName'] ?? ''),
                subtitle: Text(item['note'] ?? ''),
              );
            }) ?? [],
            const SizedBox(height: 20),
            TextField(
              controller: _vehicleOwnerController,
              decoration: const InputDecoration(labelText: 'اسم السائق'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vehicleNumberController,
              decoration: const InputDecoration(labelText: 'رقم المركبة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vehicleTypeController,
              decoration: const InputDecoration(labelText: 'نوع المركبة'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: materialType,
              items: const [
                DropdownMenuItem(value: 'مقتنيات شخصية', child: Text('مقتنيات شخصية')),
                DropdownMenuItem(value: 'مقتنيات جامعية', child: Text('مقتنيات جامعية')),
              ],
              onChanged: (v) => setState(() => materialType = v!),
              decoration: const InputDecoration(labelText: 'نوع المواد'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _returnDateController,
              readOnly: true,
              onTap: _pickReturnDate,
              decoration: const InputDecoration(labelText: 'تاريخ الإرجاع'),
            ),
            const SizedBox(height: 20),
            const Text('توقيع المدير:', style: TextStyle(fontSize: 16)),
            Signature(
              controller: managerSignature,
              height: 100,
              backgroundColor: Colors.grey[300]!,
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _approveRequest,
                icon: const Icon(Icons.check),
                label: const Text('اعتماد الطلب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00408b),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
