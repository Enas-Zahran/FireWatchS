import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'addMaintenancePrice.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/maintenance/editMaintenancePrice.dart';
class MaintenancePricesListPage extends StatefulWidget {
  const MaintenancePricesListPage({super.key});

  @override
  State<MaintenancePricesListPage> createState() => _MaintenancePricesListPageState();
}

class _MaintenancePricesListPageState extends State<MaintenancePricesListPage> {
  List<Map<String, dynamic>> prices = [];
  bool loading = true;

  final List<String> actionNames = ['صيانة', 'تركيب قطع غيار', 'تعبئة'];
  final List<String> toolTypes = ['fire extinguisher', 'hose reel', 'fire hydrant'];
  final List<String> materialTypes = [
    'ثاني اكسيد الكربون',
    'البودرة الجافة',
    'الرغوة (B.C.F)',
    'الماء',
    'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
    'بودرة',
    'CO2',
    'جميع انواع الطفايات',
  ];
  final List<String> capacities = ['2', '4', '6', '9', '12', '50', '100'];

  List<String> selectedActions = [];
  List<String> selectedTools = [];
  List<String> selectedMaterials = [];
  List<String> selectedCapacities = [];

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    setState(() => loading = true);

    final filters = <String>[];
    if (selectedActions.isNotEmpty) filters.addAll(selectedActions.map((e) => "action_name.eq.$e"));
    if (selectedTools.isNotEmpty) filters.addAll(selectedTools.map((e) => "tool_type.eq.$e"));
    if (selectedMaterials.isNotEmpty) filters.addAll(selectedMaterials.map((e) => "material_type.eq.$e"));
    if (selectedCapacities.isNotEmpty) filters.addAll(selectedCapacities.map((e) => "capacity.eq.$e"));

    dynamic data;
    if (filters.isNotEmpty) {
      data = await Supabase.instance.client
          .from('maintenance_prices')
          .select('*')
          .or(filters.join(','))
          .order('created_at', ascending: false);
    } else {
      data = await Supabase.instance.client
          .from('maintenance_prices')
          .select('*')
          .order('created_at', ascending: false);
    }

    setState(() {
      prices = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }

  void _resetFilters() {
    setState(() {
      selectedActions.clear();
      selectedTools.clear();
      selectedMaterials.clear();
      selectedCapacities.clear();
    });
    Navigator.pop(context);
    _fetchPrices();
  }

  void _applyFilters() {
    Navigator.pop(context);
    _fetchPrices();
  }

  Widget _buildCheckboxList(String title, List<String> options, List<String> selectedItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...options.map((item) => CheckboxListTile(
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
            )),
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
            child: Center(child: Text('لوحة تحكم الاجراء', style: TextStyle(color: Colors.white))),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMaintenancePricePage()),
                );
                _fetchPrices();
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('الفلاتر', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildCheckboxList('اسم الإجراء', actionNames, selectedActions),
                _buildCheckboxList('نوع الأداة', toolTypes, selectedTools),
                _buildCheckboxList('نوع المادة', materialTypes, selectedMaterials),
                _buildCheckboxList('السعة', capacities, selectedCapacities),
                ElevatedButton(onPressed: _applyFilters, child: const Text('تطبيق الفلاتر')),
                TextButton(onPressed: _resetFilters, child: const Text('إعادة تعيين')),
              ],
            ),
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : prices.isEmpty
                ? const Center(child: Text('لا توجد أسعار مضافة بعد'))
                : ListView.builder(
                    itemCount: prices.length,
                    itemBuilder: (context, index) {
                      final item = prices[index];
                      return Card(
                        margin: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text('${item['action_name']}${item['tool_type'] != null ? ' - ${item['tool_type']}' : ''}'
                              '${item['material_type'] != null ? ' - ${item['material_type']}' : ''}'
                              '${item['capacity'] != null ? ' - ${item['capacity']} كغم' : ''}'
                              '${item['component_name'] != null ? ' - ${item['component_name']}' : ''}'),
                          subtitle: Text('السعر: ${item['price']} د.أ'),
                        trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.edit, color: Colors.blue),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditMaintenancePricePage(priceEntry: item),
          ),
        );
        _fetchPrices();
      },
    ),
    IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: const Text('هل أنت متأكد أنك تريد حذف هذا السعر؟'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
              ],
            ),
          ),
        );
        if (confirm == true) {
          await Supabase.instance.client.from('maintenance_prices').delete().eq('id', item['id']);
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
