import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/tools/editToolPrice.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/tools/addPrice.dart';

class ToolPricesListPage extends StatefulWidget {
  const ToolPricesListPage({super.key});

  @override
  State<ToolPricesListPage> createState() => _ToolPricesListPageState();
}

class _ToolPricesListPageState extends State<ToolPricesListPage> {
  List<Map<String, dynamic>> prices = [];
  List<String> companies = [];
  List<String> selectedToolTypes = [];
  List<String> selectedMaterialTypes = [];
  List<String> selectedCapacities = [];
  List<String> selectedCompanies = [];
  bool loading = true;

  final toolTypes = ['fire extinguisher', 'hose reel', 'fire hydrant'];
  final materialTypes = [
    'ثاني اكسيد الكربون',
    'البودرة الجافة',
    'الرغوة (B.C.F)',
    'الماء',
    'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
  ];
  final capacities = [
    '1 kg',
    '2 kg',
    '3 kg',
    '4 kg',
    '5 kg',
    '6 kg',
    '9 kg',
    '10 kg',
    '12 kg',
    '20 kg',
    '25 kg',
    '30 kg',
    '50 kg',
    '1 L',
    '2 L',
    '3 L',
    '4 L',
    '6 L',
    '9 L',
    '25 L',
    '50 L',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
    _fetchPrices();
  }

  Future<void> _fetchCompanies() async {
    final data = await Supabase.instance.client
        .from('safety_tool_prices')
        .select('company_name')
        .neq('company_name', '')
        .order('company_name', ascending: true);

    final names =
        data.map((e) => e['company_name'].toString()).toSet().toList();
    setState(() {
      companies = names;
    });
  }

  Future<void> _fetchPrices() async {
    setState(() => loading = true);

    final query = Supabase.instance.client
        .from('safety_tool_prices')
        .select('*')
        .order('created_at', ascending: false);

    final filters = <String>[];

    if (selectedToolTypes.isNotEmpty) {
      filters.addAll(selectedToolTypes.map((e) => "tool_type.eq.$e"));
    }
    if (selectedMaterialTypes.isNotEmpty) {
      filters.addAll(selectedMaterialTypes.map((e) => "material_type.eq.$e"));
    }
    if (selectedCapacities.isNotEmpty) {
      filters.addAll(selectedCapacities.map((e) => "capacity.eq.$e"));
    }
    if (selectedCompanies.isNotEmpty) {
      filters.addAll(selectedCompanies.map((e) => "company_name.eq.$e"));
    }

    dynamic data;
    if (filters.isNotEmpty) {
      final response = await Supabase.instance.client
          .from('safety_tool_prices')
          .select('*')
          .or(filters.join(','))
          .order('created_at', ascending: false);
      data = response;
    } else {
      data = await query;
    }

    setState(() {
      prices = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }

  void _applyFilters() {
    Navigator.pop(context);
    _fetchPrices();
  }

  void _resetFilters() {
    setState(() {
      selectedToolTypes.clear();
      selectedMaterialTypes.clear();
      selectedCapacities.clear();
      selectedCompanies.clear();
    });
    Navigator.pop(context);
    _fetchPrices();
  }

  Widget _buildCheckboxList(
    String title,
    List<String> options,
    List<String> selectedItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...options.map(
          (item) => CheckboxListTile(
            value: selectedItems.contains(item),
            title: Text(item),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedItems.add(item);
                } else {
                  selectedItems.remove(item);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'قائمة أسعار أدوات السلامة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'فلتر',
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'اضافة سعر ',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddToolPricePage()),
                );
                _fetchPrices();
                _fetchCompanies();
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'الفلاتر',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildCheckboxList('نوع الأداة', toolTypes, selectedToolTypes),
                _buildCheckboxList(
                  'نوع المادة',
                  materialTypes,
                  selectedMaterialTypes,
                ),
                _buildCheckboxList('السعة', capacities, selectedCapacities),
                _buildCheckboxList('الشركة', companies, selectedCompanies),
                ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('تطبيق الفلاتر'),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('إعادة تعيين'),
                ),
              ],
            ),
          ),
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : prices.isEmpty
                ? const Center(child: Text('لا توجد أسعار مضافة بعد'))
                : ListView.builder(
                  itemCount: prices.length,
                  itemBuilder: (context, index) {
                    final item = prices[index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          '${item['tool_type']} - ${item['material_type']} - ${item['capacity']}',
                        ),
                        subtitle: Text(
                          'السعر: ${item['price']} د.أ\nالشركة: ${item['company_name'] ?? 'غير محددة'}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) =>
                                            EditToolPricePage(priceEntry: item),
                                  ),
                                );
                                _fetchPrices();
                                _fetchCompanies();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: AlertDialog(
                                          title: const Text('تأكيد الحذف'),
                                          content: const Text(
                                            'هل أنت متأكد أنك تريد حذف هذا السعر؟',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('إلغاء'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('حذف'),
                                            ),
                                          ],
                                        ),
                                      ),
                                );
                                if (confirm == true) {
                                  await Supabase.instance.client
                                      .from('safety_tool_prices')
                                      .delete()
                                      .eq('id', item['id']);
                                  _fetchPrices();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
