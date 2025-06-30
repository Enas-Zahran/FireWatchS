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

  List<Map<String, dynamic>> materials = [];

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

    // Initialize materials list
    final List<dynamic>? tools = data['tool_codes'];
    if (tools != null) {
      materials = tools.map((item) {
        return {
          'toolName': item['toolName'] ?? '',
          'note': item['note'] ?? '',
        };
      }).toList();
    }
  }

  void _addNewMaterial() {
    setState(() {
      materials.add({'toolName': '', 'note': ''});
    });
  }

  void _removeMaterial(int index) {
    setState(() {
      materials.removeAt(index);
    });
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
            'tool_codes': materials,
            'usage_reason': materials.map((m) => m['note']).join(' - '),
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
          child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                const Text('المواد المطلوبة:', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                ...materials.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: item['toolName'],
                            decoration: const InputDecoration(labelText: 'اسم الأداة'),
                            onChanged: (val) => materials[i]['toolName'] = val,
                          ),
                          TextFormField(
                            initialValue: item['note'],
                            decoration: const InputDecoration(labelText: 'السبب'),
                            onChanged: (val) => materials[i]['note'] = val,
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _removeMaterial(i),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('حذف', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addNewMaterial,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة أداة جديدة'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: updateRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00408b),
                  ),
                  child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
