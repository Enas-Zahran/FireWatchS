import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class EditMaintenancePricePage extends StatefulWidget {
  final Map<String, dynamic> priceEntry;
  const EditMaintenancePricePage({super.key, required this.priceEntry});

  @override
  State<EditMaintenancePricePage> createState() =>
      _EditMaintenancePricePageState();
}

class _EditMaintenancePricePageState extends State<EditMaintenancePricePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.priceEntry['price'].toString(),
    );
  }

  Future<void> _updatePrice() async {
    if (!_formKey.currentState!.validate()) return;

    final newPrice = double.parse(_priceController.text.trim());

    await Supabase.instance.client
        .from('maintenance_prices')
        .update({'price': newPrice})
        .eq('id', widget.priceEntry['id']);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تحديث السعر بنجاح')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final description = [
      widget.priceEntry['action_name'],
      widget.priceEntry['tool_type'],
      widget.priceEntry['material_type'],
      widget.priceEntry['capacity'],
      widget.priceEntry['component_name'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(' - ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: const Text(
              'تعديل السعر',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تعديل السعر لـ: $description'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: customInputDecoration.copyWith(
                    labelText: 'السعر الجديد',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'يرجى إدخال السعر';
                    final num? parsed = num.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) return 'سعر غير صالح';
                    return null;
                  },
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _updatePrice,
                  child: const Text('تحديث'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00408b),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(400, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
