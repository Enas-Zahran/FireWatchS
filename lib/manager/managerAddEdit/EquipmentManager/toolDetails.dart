import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/toolReports.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/toolsAction.dart';
import 'dart:ui'as ui;
class ToolDetailsPage extends StatelessWidget {
  final Map<String, dynamic> tool;

  const ToolDetailsPage({Key? key, required this.tool}) : super(key: key);

  String formatDate(dynamic date) {
    if (date == null) return 'غير محدد';
    try {
      final parsed = DateTime.parse(date.toString());
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (e) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = tool['name'] ?? '';
    final type = tool['type'] ?? '';
    final material = tool['material_type'] ?? '';
    final capacity = tool['capacity'] ?? '';
    final company = tool['company_name'] ?? 'غير محددة';
    final price = (tool['price'] as num?)?.toDouble();
    final lastMaintenance = formatDate(tool['last_maintenance_date']);
    final nextMaintenance = formatDate(tool['next_maintenance_date']);

    final priceText = price != null ? '${price.toStringAsFixed(2)} د.أ' : 'غير متاح';

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: Center(
            child: Text(name, style: const TextStyle(color: Colors.white)),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildInfoTile('نوع الأداة', type),
                  buildInfoTile('نوع المادة', material),
                  buildInfoTile('السعة', capacity),
                  buildInfoTile('الشركة', company),
                  buildInfoTile('آخر صيانة تمت', lastMaintenance),
                  buildInfoTile('الصيانة القادمة', nextMaintenance),
                  const SizedBox(height: 12),
                  buildInfoTile('السعر الأساسي', priceText, bold: true),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ToolReportsPage(toolId: tool['id']),
                          ),
                        );
                      },
                      child: const Text('عرض جميع التقارير', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff00408b),
                        minimumSize: const Size(400, 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ToolActionsPage(toolId: tool['id']),
                          ),
                        );
                      },
                      child: const Text('عرض جميع الإجراءات', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff00408b),
                        minimumSize: const Size(400, 50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoTile(String label, String value, {bool bold = false}) {
    return SizedBox(
      width: 400,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
               Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: bold ? const Color(0xff00408b) : Colors.black87,
              ),
            ),
         
          ],
        ),
      ),
    );
  }
}
