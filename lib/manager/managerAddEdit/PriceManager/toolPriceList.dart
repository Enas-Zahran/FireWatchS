import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/editToolPrice.dart'; 
import 'package:FireWatch/manager/managerAddEdit/PriceManager/addPrice.dart';
class ToolPricesListPage extends StatefulWidget {
  const ToolPricesListPage({super.key});

  @override
  State<ToolPricesListPage> createState() => _ToolPricesListPageState();
}

class _ToolPricesListPageState extends State<ToolPricesListPage> {
  List<Map<String, dynamic>> prices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    setState(() => loading = true);
    final data = await Supabase.instance.client
        .from('safety_tool_prices')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      prices = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }

  Future<void> _deletePrice(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا السعر؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client
          .from('safety_tool_prices')
          .delete()
          .eq('id', id);
      _fetchPrices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: const Text('قائمة أسعار أدوات السلامة',style:TextStyle(color: Colors.white) ,)),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
         actions: [
    IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
     onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>AddToolPricePage() ,
                                    ),
                                  );
                                  _fetchPrices();
                                },
                              ),
    
  ],
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
                          title: Text(
                              '${item['tool_type']} - ${item['material_type']} - ${item['capacity']}'),
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
                                      builder: (_) => EditToolPricePage(priceEntry: item),
                                    ),
                                  );
                                  _fetchPrices();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePrice(item['id']),
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
