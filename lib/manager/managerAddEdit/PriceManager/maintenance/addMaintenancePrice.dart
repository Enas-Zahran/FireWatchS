import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class AddMaintenancePricePage extends StatefulWidget {
  const AddMaintenancePricePage({super.key});

  @override
  State<AddMaintenancePricePage> createState() =>
      _AddMaintenancePricePageState();
}

class _AddMaintenancePricePageState extends State<AddMaintenancePricePage> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  String? _actionName;
  String? _toolType;
  String? _materialType;
  String? _capacity;
  String? _componentName;

  final List<String> actionNames = ['صيانة', 'تركيب قطع غيار', 'تعبئة'];
  final List<String> componentNamesAll = [
    'خرطوم طفاية حريق',
    'سلندر خارجي لطفاية الحريق',
    'ساعة ضغط',
    'مقبض طفاية الحريق',
    'قاذف طفاية الحريق',
    'طقم جلود(كسكيت)',
  ];

  final Map<String, List<String>> capacitiesByMaterial = {
    'البودرة الجافة': ['2', '4', '6', '9', '12', '50', '100'],
    'ثاني اكسيد الكربون': ['2', '6'],
  };

  void _resetSelections() {
    _toolType = null;
    _materialType = null;
    _capacity = null;
    _componentName = null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _actionName == null) return;

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال سعر صالح')));
      return;
    }

    final data = {
      'action_name': _actionName,
      'tool_type': _toolType,
      'material_type': _materialType,
      'capacity': _capacity,
      'component_name': _componentName,
      'price': price,
    }..removeWhere((key, value) => value == null);

    await Supabase.instance.client.from('maintenance_prices').insert(data);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة السعر بنجاح')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'إضافة سعر لإجراء',
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
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  value: _actionName,
                  decoration: customInputDecoration.copyWith(
                    labelText: 'اسم الإجراء',
                  ),
                  items:
                      actionNames
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _actionName = val;
                      _resetSelections();
                      if (val == 'صيانة' || val == 'تعبئة') {
                        _toolType = 'fire extinguisher';
                      }
                    });
                  },
                  validator:
                      (val) => val == null ? 'يرجى اختيار اسم الإجراء' : null,
                ),
                const SizedBox(height: 12),

                if (_actionName == 'صيانة') ...[
                  buildMaterialDropdown([
                    'البودرة الجافة',
                    'ثاني اكسيد الكربون',
                  ]),
                  const SizedBox(height: 12),
                  if (_materialType != null &&
                      capacitiesByMaterial.containsKey(_materialType))
                    buildCapacityDropdown(),
                ],

                if (_actionName == 'تعبئة') ...[
                  buildMaterialDropdown([
                    'ثاني اكسيد الكربون',
                    'البودرة الجافة',
                  ]),
                ],

                if (_actionName == 'تركيب قطع غيار') ...[
                  buildMaterialDropdown([
                    'ثاني اكسيد الكربون',
                    'البودرة الجافة',
                    'جميع انواع الطفايات',
                  ]),
                  const SizedBox(height: 12),
                  if (_materialType == 'ثاني اكسيد الكربون')
                    buildComponentDropdown(['محبس طفاية CO2'])
                  else if (_materialType == 'البودرة الجافة')
                    buildComponentDropdown([
                      'سعر رأس الطفاية كامل لطفاية البودرة مع المقبض و الخرطوم و السيفون الداخلي و ساعة الضغط و مسمار الأمان',
                    ])
                  else if (_materialType == 'جميع انواع الطفايات')
                    buildComponentDropdown(componentNamesAll),
                ],

                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: customInputDecoration.copyWith(
                    labelText: 'السعر',
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00408b),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(400, 50),
                  ),
                  child: const Text('إضافة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMaterialDropdown(List<String> items) {
    return DropdownButtonFormField<String>(
      value: _materialType,
      decoration: customInputDecoration.copyWith(labelText: 'نوع المادة'),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged:
          (val) => setState(() {
            _materialType = val;
            _capacity = null;
            _componentName = null;
          }),
      validator: (val) => val == null ? 'يرجى اختيار نوع المادة' : null,
    );
  }

  Widget buildCapacityDropdown() {
    final caps = capacitiesByMaterial[_materialType]!;
    return DropdownButtonFormField<String>(
      value: _capacity,
      decoration: customInputDecoration.copyWith(labelText: 'السعة (كغم)'),
      items:
          caps
              .map((e) => DropdownMenuItem(value: e, child: Text('$e كغم')))
              .toList(),
      onChanged: (val) => setState(() => _capacity = val),
      validator: (val) => val == null ? 'يرجى اختيار السعة' : null,
    );
  }

  Widget buildComponentDropdown(List<String> items) {
    return DropdownButtonFormField<String>(
      value: _componentName,
      decoration: customInputDecoration.copyWith(labelText: 'اسم القطعة'),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) => setState(() => _componentName = val),
      validator: (val) => val == null ? 'يرجى اختيار اسم القطعة' : null,
    );
  }
}
