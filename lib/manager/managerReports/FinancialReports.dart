import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class FinancialReportsPage extends StatefulWidget {
  const FinancialReportsPage({super.key});

  @override
  State<FinancialReportsPage> createState() => _FinancialReportsPageState();
}

class _FinancialReportsPageState extends State<FinancialReportsPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;

  List<Map<String, dynamic>> allTools = [];
  List<Map<String, dynamic>> tools = [];

  DateTime? startDate;
  DateTime? endDate;
  String? selectedType;
  String? selectedMaterial;
  String? selectedCompany;
  double? minPrice;
  double? maxPrice;

  Set<String> allTypes = {};
  Set<String> allMaterials = {};
  Set<String> allCompanies = {};

  @override
  void initState() {
    super.initState();
    _loadTools();
  }

  Future<void> _loadTools() async {
    final response = await supabase
        .from('safety_tools')
        .select('*')
        .order('purchase_date', ascending: false);

    final data = List<Map<String, dynamic>>.from(response);

    setState(() {
      allTools = data;
      tools = data;
      allTypes = data.map((e) => e['type']?.toString() ?? '').toSet();
      allMaterials =
          data.map((e) => e['material_type']?.toString() ?? '').toSet();
      allCompanies =
          data.map((e) => e['company_name']?.toString() ?? '').toSet();
      isLoading = false;
    });
  }

  void _applyFilters() {
    final filtered =
        allTools.where((tool) {
          final date = DateTime.tryParse(tool['purchase_date'] ?? '');
          final price = double.tryParse(tool['price'].toString());

          final matchDate =
              (startDate == null ||
                  (date != null &&
                      date.isAfter(
                        startDate!.subtract(const Duration(days: 1)),
                      ))) &&
              (endDate == null ||
                  (date != null &&
                      date.isBefore(endDate!.add(const Duration(days: 1)))));
          final matchType =
              selectedType == null || tool['type'] == selectedType;
          final matchMaterial =
              selectedMaterial == null ||
              tool['material_type'] == selectedMaterial;
          final matchCompany =
              selectedCompany == null ||
              tool['company_name'] == selectedCompany;
          final matchPrice =
              (minPrice == null || (price != null && price >= minPrice!)) &&
              (maxPrice == null || (price != null && price <= maxPrice!));

          return matchDate &&
              matchType &&
              matchMaterial &&
              matchCompany &&
              matchPrice;
        }).toList();

    setState(() => tools = filtered);
  }

  double _calculateTotalPrice() {
    return tools.fold(0.0, (sum, tool) {
      final price = double.tryParse(tool['price'].toString());
      return sum + (price ?? 0);
    });
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تقارير الشراء',
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
                          runSpacing: 8,
                          spacing: 12,
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
                              'نوع الأداة',
                              selectedType,
                              allTypes,
                              (v) => setState(() => selectedType = v),
                            ),
                            _buildDropdown(
                              'نوع المادة',
                              selectedMaterial,
                              allMaterials,
                              (v) => setState(() => selectedMaterial = v),
                            ),
                            _buildDropdown(
                              'اسم الشركة',
                              selectedCompany,
                              allCompanies,
                              (v) => setState(() => selectedCompany = v),
                            ),
                            _buildPriceField(
                              'السعر الأدنى',
                              (val) => minPrice = double.tryParse(val),
                            ),
                            _buildPriceField(
                              'السعر الأعلى',
                              (val) => maxPrice = double.tryParse(val),
                            ),
                            ElevatedButton(
                              onPressed: _applyFilters,
                              child: const Text('تطبيق الفلاتر'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  selectedType = null;
                                  selectedMaterial = null;
                                  selectedCompany = null;
                                  minPrice = null;
                                  maxPrice = null;
                                  startDate = null;
                                  endDate = null;
                                  tools = allTools;
                                });
                              },
                              child: const Text('إعادة تعيين'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child:
                          tools.isEmpty
                              ? const Center(
                                child: Text('لا توجد أدوات تطابق الفلاتر'),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: tools.length,
                                itemBuilder: (context, index) {
                                  final tool = tools[index];
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      title: Text('الأداة: ${tool['name']}'),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'النوع: ${tool['type']} | المادة: ${tool['material_type']} | السعة: ${tool['capacity']} كغم',
                                          ),
                                          Text('السعر: ${tool['price']} د.أ'),
                                          Text(
                                            'الشركة: ${tool['company_name'] ?? 'غير محددة'}',
                                          ),
                                          Text(
                                            'تاريخ الشراء: ${formatDate(tool['purchase_date'])}',
                                          ),
                                          Text(
                                            'الصيانة القادمة: ${formatDate(tool['next_maintenance_date'])}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'المجموع الكلي: ${_calculateTotalPrice().toStringAsFixed(2)} د.أ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
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

  Widget _buildPriceField(String label, void Function(String) onChanged) {
    return SizedBox(
      width: 140,
      child: TextFormField(
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
      ),
    );
  }
}
