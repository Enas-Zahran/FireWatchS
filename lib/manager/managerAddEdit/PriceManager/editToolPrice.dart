import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class EditToolPricePage extends StatefulWidget {
  final Map<String, dynamic> priceEntry;
  const EditToolPricePage({super.key, required this.priceEntry});

  @override
  State<EditToolPricePage> createState() => _EditToolPricePageState();
}

class _EditToolPricePageState extends State<EditToolPricePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.priceEntry['price'].toString());
  }

  Future<void> _updatePrice() async {
    if (!_formKey.currentState!.validate()) return;

    await Supabase.instance.client
        .from('safety_tool_prices')
        .update({'price': double.parse(_priceController.text.trim())})
        .eq('id', widget.priceEntry['id']);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث السعر بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        '${widget.priceEntry['tool_type']} - ${widget.priceEntry['material_type']} - ${widget.priceEntry['capacity']}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('تعديل السعر',style: TextStyle(color: Colors.white),)),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
        
              children: [
                 Text('تعديل السعر: $title'),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: customInputDecoration.copyWith(labelText: 'السعر الجديد'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'يرجى إدخال السعر';
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
