import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class AddToolPricePage extends StatefulWidget {
  const AddToolPricePage({super.key});

  @override
  State<AddToolPricePage> createState() => _AddToolPricePageState();
}

class _AddToolPricePageState extends State<AddToolPricePage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  String? _selectedToolType;
  String? _selectedMaterialType;
  String? _selectedCapacity;

  final Map<String, List<String>> materialOptions = {
    'fire extinguisher': [
      'ثاني اكسيد الكربون',
      'البودرة الجافة',
      'الرغوة (B.C.F)',
      'الماء',
      'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي'
    ],
    'hose reel': ['الماء'],
    'fire hydrant': ['الماء'],
  };

  final Map<String, List<String>> capacityOptions = {
    'ثاني اكسيد الكربون': ['2 kg', '5 kg', '6 kg', '10 kg', '20 kg', '30 kg'],
    'البودرة الجافة': ['1 kg', '2 kg', '6 kg', '12 kg', '25 kg', '50 kg'],
    'الرغوة (B.C.F)': ['1 L', '2 L', '3 L', '4 L', '6 L', '9 L', '25 L', '50 L'],
    'الماء': ['1 L', '2 L', '3 L', '4 L', '6 L', '9 L', '25 L', '50 L'],
    'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي': ['1 kg', '2 kg', '3 kg', '4 kg', '6 kg', '9 kg', '25 kg', '50 kg'],
  };

 Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  // Safe unwrap because form validation already ensures they're not null
  final toolType = _selectedToolType!;
  final materialType = _selectedMaterialType!;
  final capacity = _selectedCapacity!;
  final price = double.parse(_priceController.text.trim());

  // Check if this combination already exists
  final existing = await Supabase.instance.client
      .from('safety_tool_prices')
      .select()
      .eq('tool_type', toolType)
      .eq('material_type', materialType)
      .eq('capacity', capacity)
      .maybeSingle();

  if (existing != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إضافة هذا السعر مسبقاً'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Insert only if not duplicate
  await Supabase.instance.client.from('safety_tool_prices').insert({
    'tool_type': toolType,
    'material_type': materialType,
    'capacity': capacity,
    'price': price,
  });

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تمت إضافة السعر بنجاح')),
  );
  Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة سعر لأداة السلامة'),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                buildDropdown(
                  label: 'نوع الأداة',
                  value: _selectedToolType,
                  items: ['fire extinguisher', 'hose reel', 'fire hydrant'],
                  onChanged: (val) {
                    setState(() {
                      _selectedToolType = val;
                      _selectedMaterialType = null;
                      _selectedCapacity = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_selectedToolType != null)
                  buildDropdown(
                    label: 'نوع المادة',
                    value: _selectedMaterialType,
                    items: materialOptions[_selectedToolType!]!,
                    onChanged: (val) {
                      setState(() {
                        _selectedMaterialType = val;
                        _selectedCapacity = null;
                      });
                    },
                  ),
                const SizedBox(height: 12),
                if (_selectedMaterialType != null)
                  buildDropdown(
                    label: 'السعة',
                    value: _selectedCapacity,
                    items: capacityOptions[_selectedMaterialType!]!,
                    onChanged: (val) {
                      setState(() => _selectedCapacity = val);
                    },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: customInputDecoration.copyWith(labelText: 'السعر'),
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
                  onPressed: _submit,
                  child: const Text('إضافة'),
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

  Widget buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: customInputDecoration.copyWith(labelText: label),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'يرجى اختيار $label' : null,
    );
  }
}
