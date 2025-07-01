import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class FinalExportPreviewPage extends StatelessWidget {
  final Map<String, dynamic> request;
  final String technicianName;

  const FinalExportPreviewPage({
    super.key,
    required this.request,
    required this.technicianName,
  });

  Uint8List _decodeSignature(dynamic value) {
    if (value is String) {
      try {
        return base64Decode(value);
      } catch (e) {
        try {
          return Uint8List.fromList(List<int>.from(jsonDecode(value)));
        } catch (_) {
          throw Exception('Invalid base64 or JSON format');
        }
      }
    } else if (value is List) {
      return Uint8List.fromList(List<int>.from(value));
    } else {
      throw Exception('Unknown signature format');
    }
  }

  @override
  Widget build(BuildContext context) {
    final returnDate =
        request['return_date'] != null
            ? DateFormat.yMd().format(DateTime.parse(request['return_date']))
            : '---';

    final toolCodes = request['tool_codes'] as List<dynamic>? ?? [];
    final materialType = request['material_type'] ?? '---';
    final vehicleOwner = request['vehicle_owner'] ?? '---';
    final vehicleNumber = request['vehicle_number'] ?? '---';
    final vehicleType = request['vehicle_type'] ?? '---';
    final technicianDisplayName = request['created_by_name'] ?? '---';

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'معاينة تصريح الإخراج النهائي',
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
                  'جامعة العلوم والتكنولوجيا الأردنية / دائرة السلامة والصحة المهنية والبيئية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'اسم الفني: $technicianDisplayName',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      'تاريخ الإرجاع: $returnDate',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'اسم السائق: $vehicleOwner',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'رقم المركبة: $vehicleNumber',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'نوع المركبة: $vehicleType',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'نوع المواد: $materialType',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                'المواد المطلوبة:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...toolCodes.map((item) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(item['toolName'] ?? ''),
                    subtitle: Text('السبب: ${item['note'] ?? ''}'),
                    leading: const Icon(Icons.build),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              const Text('توقيع الفني:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              if (request['technician_signature'] != null)
                Image.memory(
                  _decodeSignature(request['technician_signature']),
                  height: 100,
                  fit: BoxFit.contain,
                )
              else
                const Text(
                  'لا يوجد توقيع',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 8),
              const Text('توقيع المدير:', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              if (request['manager_signature'] != null)
                Image.memory(
                  _decodeSignature(request['manager_signature']),
                  height: 100,
                  fit: BoxFit.contain,
                )
              else
                const Text(
                  'لا يوجد توقيع',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              Center(
                child: const Text(
                  'أتعهد بإعادة المواد فور انتهاء العمل المطلوب',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
