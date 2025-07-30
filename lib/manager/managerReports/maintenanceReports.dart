import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class MaintenanceReportsPage extends StatefulWidget {
  const MaintenanceReportsPage({super.key});

  @override
  State<MaintenanceReportsPage> createState() => _MaintenanceReportsPageState();
}

class _MaintenanceReportsPageState extends State<MaintenanceReportsPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;

  List<Map<String, dynamic>> allLogs = [];
  List<Map<String, dynamic>> logs = [];

  DateTime? startDate;
  DateTime? endDate;
  String? selectedTool;
  String? selectedTechnician;

  Set<String> allTools = {};
  Set<String> allTechnicians = {};

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final response = await supabase
        .from(
          'tool_action_logs_with_details',
        ) // make sure this view exists and is correct
        .select('*')
        .order('performed_at', ascending: false);

    final data = List<Map<String, dynamic>>.from(response);

    setState(() {
      allLogs = data;
      logs = data;
      allTools = data.map((e) => e['tool_name']?.toString() ?? '').toSet();
      allTechnicians =
          data.map((e) => e['technician_name']?.toString() ?? '').toSet();
      isLoading = false;
    });
  }

  void _applyFilters() {
    final filtered =
        allLogs.where((log) {
          final date = DateTime.tryParse(log['performed_at'] ?? '');

          final matchDate =
              (startDate == null ||
                  (date != null &&
                      date.isAfter(
                        startDate!.subtract(const Duration(days: 1)),
                      ))) &&
              (endDate == null ||
                  (date != null &&
                      date.isBefore(endDate!.add(const Duration(days: 1)))));

          final matchTool =
              selectedTool == null || log['tool_name'] == selectedTool;
          final matchTech =
              selectedTechnician == null ||
              log['technician_name'] == selectedTechnician;

          return matchDate && matchTool && matchTech;
        }).toList();

    setState(() => logs = filtered);
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  double _calculateTotal() {
    return logs.fold(
      0.0,
      (sum, log) => sum + ((log['price'] ?? 0.0) as num).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تقارير الصيانة',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff00408b),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    ExpansionTile(
                      title: const Text('فلترة النتائج'),
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildDatePicker(
                              'من تاريخ',
                              startDate,
                              (picked) => setState(() => startDate = picked),
                            ),
                            _buildDatePicker(
                              'إلى تاريخ',
                              endDate,
                              (picked) => setState(() => endDate = picked),
                            ),
                            _buildDropdown(
                              'اسم الأداة',
                              selectedTool,
                              allTools,
                              (val) => setState(() => selectedTool = val),
                            ),
                            _buildDropdown(
                              'اسم الفني',
                              selectedTechnician,
                              allTechnicians,
                              (val) => setState(() => selectedTechnician = val),
                            ),
                            ElevatedButton(
                              onPressed: _applyFilters,
                              child: const Text('تطبيق الفلاتر'),
                            ),
                            TextButton(
                              onPressed:
                                  () => setState(() {
                                    startDate = null;
                                    endDate = null;
                                    selectedTool = null;
                                    selectedTechnician = null;
                                    logs = allLogs;
                                  }),
                              child: const Text('إعادة تعيين'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child:
                          logs.isEmpty
                              ? const Center(child: Text('لا توجد نتائج'))
                              : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        'الأداة: ${log['tool_name']}',
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'الإجراء: ${log['action_name']}',
                                          ),
                                          Text('السعر: ${log['price']} د.أ'),
                                          Text(
                                            'التاريخ: ${formatDate(log['performed_at'])}',
                                          ),
                                          Text(
                                            'الفني: ${log['technician_name']}',
                                          ),
                                          if (log['notes'] != null &&
                                              log['notes']
                                                  .toString()
                                                  .isNotEmpty)
                                            Text('ملاحظات: ${log['notes']}'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'المجموع الكلي: ${_calculateTotal().toStringAsFixed(2)} د.أ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    Set<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButton<String>(
      hint: Text(label),
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? currentValue,
    void Function(DateTime) onPicked,
  ) {
    return TextButton.icon(
      icon: const Icon(Icons.date_range),
      label: Text(
        currentValue == null
            ? label
            : DateFormat('yyyy-MM-dd').format(currentValue),
      ),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: currentValue ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
    );
  }
}
