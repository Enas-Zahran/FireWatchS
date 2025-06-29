import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class FinalExportPreviewPage extends StatelessWidget {
  final Map<String, dynamic> request;
  final String technicianName;

  const FinalExportPreviewPage({
    super.key,
    required this.request,
    required this.technicianName,
  });

  @override
  Widget build(BuildContext context) {
    final returnDate =
        request['return_date'] != null
            ? DateFormat.yMd().format(DateTime.parse(request['return_date']))
            : '---';

    final materialType = request['material_type'] ?? '---';

    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة تصريح الإخراج النهائي'),
        backgroundColor: const Color(0xff00408b),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Implement actual print logic later
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تنفيذ أمر الطباعة...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اسم الفني: $technicianName',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Text(
              'المواد المطلوبة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(request['tool_codes'] as List<dynamic>? ?? []).map((item) {
              return ListTile(
                leading: const Icon(Icons.build),
                title: Text(item['toolName'] ?? ''),
                subtitle: Text(item['note'] ?? ''),
              );
            }).toList(),
            const Divider(height: 32),
            Text('اسم السائق: ${request['vehicle_owner'] ?? "---"}'),
            Text('رقم المركبة: ${request['vehicle_number'] ?? "---"}'),
            Text('نوع المركبة: ${request['vehicle_type'] ?? "---"}'),
            Text('نوع المواد: $materialType'),
            Text('تاريخ الإرجاع: $returnDate'),
            const SizedBox(height: 20),
            const Text('توقيع المدير:', style: TextStyle(fontSize: 16)),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.grey[200],
              ),
              child:
                  request['manager_signature'] != null
                      ? Image.memory(
                        request['manager_signature'],
                        fit: BoxFit.contain,
                      )
                      : const Center(child: Text('لا يوجد توقيع')),
            ),
    
            const SizedBox(height: 20),
            const Text(
              'أتعهد بإعادة المواد فور انتهاء العمل المطلوب',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
