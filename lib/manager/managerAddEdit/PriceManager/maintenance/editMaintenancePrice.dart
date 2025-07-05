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
  String? _actionName;
  String? _toolType;
  String? _materialType;
  String? _capacity;
  String? _componentName;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.priceEntry['price'].toString(),
    );
    _actionName = widget.priceEntry['action_name'];
    _toolType = widget.priceEntry['tool_type'];
    _materialType = widget.priceEntry['material_type'];
    _capacity = widget.priceEntry['capacity'];
    _componentName = widget.priceEntry['component_name'];
  }

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

  Future<void> _updatePrice() async {
    if (!_formKey.currentState!.validate()) return;

    final newPrice = double.parse(_priceController.text.trim());

    final updateData = {
      'price': newPrice,
      'action_name': _actionName,
      'tool_type': _toolType,
      'material_type': _materialType,
      'capacity': _capacity,
      'component_name': _componentName,
    }..removeWhere((k, v) => v == null);

    await Supabase.instance.client
        .from('maintenance_prices')
        .update(updateData)
        .eq('id', widget.priceEntry['id']);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تحديث السعر بنجاح')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                DropdownButtonFormField<String>(
                  value: _actionName,
                  decoration: customInputDecoration.copyWith(
                    labelText: 'اسم الإجراء',
                  ),
                  items:
                      ['صيانة', 'تركيب قطع غيار', 'تعبئة']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      _actionName = val;
                      _materialType = null;
                      _capacity = null;
                      _componentName = null;
                    });
                  },
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _toolType,
                  decoration: customInputDecoration.copyWith(
                    labelText: 'نوع الأداة',
                  ),
                  items:
                      ['fire extinguisher']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _toolType = val),
                ),

                if (_actionName != null && _actionName != 'تعبئة')
                  DropdownButtonFormField<String>(
                    value: _materialType,
                    decoration: customInputDecoration.copyWith(
                      labelText: 'نوع المادة',
                    ),
                    items:
                        [
                              'البودرة الجافة',
                              'ثاني اكسيد الكربون',
                              'الرغوة (B.C.F)',
                              'الماء',
                              'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged:
                        (val) => setState(() {
                          _materialType = val;
                          _capacity = null;
                          _componentName = null;
                        }),
                  ),

                if (_actionName == 'صيانة' &&
                    _materialType != null &&
                    capacitiesByMaterial.containsKey(_materialType!))
                  DropdownButtonFormField<String>(
                    value: _capacity,
                    decoration: customInputDecoration.copyWith(
                      labelText: 'السعة',
                    ),
                    items:
                        capacitiesByMaterial[_materialType]!
                            .map(
                              (e) => DropdownMenuItem(
                                value: '$e kg',
                                child: Text('$e kg'),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => _capacity = val),
                  ),

                if (_actionName == 'تركيب قطع غيار') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _componentName,
                    decoration: customInputDecoration.copyWith(
                      labelText: 'اسم القطعة',
                    ),
                    items:
                        (() {
                          List<String> items = [];

                          if (_materialType == 'ثاني اكسيد الكربون') {
                            items = ['محبس طفاية CO2', ...componentNamesAll];
                          } else if (_materialType == 'البودرة الجافة') {
                            items = [
                              'سعر رأس الطفاية كامل لطفاية البودرة مع المقبض و الخرطوم و السيفون الداخلي و ساعة الضغط و مسمار الأمان',
                              ...componentNamesAll,
                            ];
                          } else if ([
                            'الرغوة (B.C.F)',
                            'الماء',
                            'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
                          ].contains(_materialType)) {
                            items = componentNamesAll;
                          }

                          return items
                              .map<DropdownMenuItem<String>>(
                                (e) => DropdownMenuItem<String>(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList();
                        })(),
                    onChanged: (val) => setState(() => _componentName = val),
                  ),
                ],

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
