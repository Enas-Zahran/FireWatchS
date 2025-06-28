import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExportRequestDetailsPage extends StatefulWidget {
  final Map<String, dynamic> request;

  const ExportRequestDetailsPage({super.key, required this.request});

  @override
  State<ExportRequestDetailsPage> createState() => _ExportRequestDetailsPageState();
}

class _ExportRequestDetailsPageState extends State<ExportRequestDetailsPage> {
  final supabase = Supabase.instance.client;

  late TextEditingController vehicleOwnerController;
  late TextEditingController vehicleNumberController;
  late TextEditingController vehicleTypeController;
  late TextEditingController returnDateController;
  String materialType = 'مقتنيات شخصية';

  @override
  void initState() {
    super.initState();
    final data = widget.request;
    vehicleOwnerController = TextEditingController(text: data['vehicle_owner'] ?? '');
    vehicleNumberController = TextEditingController(text: data['vehicle_number'] ?? '');
    vehicleTypeController = TextEditingController(text: data['vehicle_type'] ?? '');
    returnDateController = TextEditingController(
      text: data['return_date'] != null ? data['return_date'].toString().split('T').first : '',
    );
    materialType = data['material_type'] ?? 'مقتنيات شخصية';
  }

  Future<void> updateRequest() async {
    try {
      await supabase
          .from('export_requests')
          .update({
            'vehicle_owner': vehicleOwnerController.text.trim(),
            'vehicle_number': vehicleNumberController.text.trim(),
            'vehicle_type': vehicleTypeController.text.trim(),
            'material_type': materialType,
            'return_date': returnDateController.text.isNotEmpty
                ? DateTime.tryParse(returnDateController.text)?.toIso8601String()
                : null,
          })
          .eq('id', widget.request['id']);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل طلب الإخراج'),
          backgroundColor: const Color(0xff00408b),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: vehicleOwnerController,
                decoration: const InputDecoration(labelText: 'اسم السائق'),
              ),
              TextField(
                controller: vehicleNumberController,
                decoration: const InputDecoration(labelText: 'رقم المركبة'),
              ),
              TextField(
                controller: vehicleTypeController,
                decoration: const InputDecoration(labelText: 'نوع المركبة'),
              ),
              DropdownButtonFormField<String>(
                value: materialType,
                decoration: const InputDecoration(labelText: 'نوع المواد'),
                items: const [
                  DropdownMenuItem(value: 'مقتنيات شخصية', child: Text('مقتنيات شخصية')),
                  DropdownMenuItem(value: 'مقتنيات جامعية', child: Text('مقتنيات جامعية')),
                ],
                onChanged: (val) => setState(() => materialType = val!),
              ),
              TextField(
                controller: returnDateController,
                decoration: const InputDecoration(labelText: 'تاريخ الإرجاع'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateRequest,
                child: const Text('حفظ التعديلات'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
