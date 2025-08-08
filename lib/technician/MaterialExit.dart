import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:ui' as ui;

class MaterialExitAuthorizationPage extends StatefulWidget {
  const MaterialExitAuthorizationPage({super.key});

  @override
  State<MaterialExitAuthorizationPage> createState() =>
      _MaterialExitAuthorizationPageState();
}

class _MaterialExitAuthorizationPageState
    extends State<MaterialExitAuthorizationPage> {
  final _vehicleController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _returnDateController = TextEditingController();
  final SignatureController technicianSignature = SignatureController(
    penStrokeWidth: 2,
  );
  DateTime? selectedReturnDate;

  String materialType = 'مقتنيات شخصية';
  String technicianName = '';
  bool agree = false;
  bool isLoading = true;
  String? requestId;

  List<Map<String, dynamic>> materials = [];

  @override
  void initState() {
    super.initState();
    _fetchTechnicianName();
    _loadExportRequest();
  }

  Widget buildMaterialDropdown(int index, List<String> items) {
    return DropdownButtonFormField<String>(
      value: materials[index]['material_type'],
      decoration: const InputDecoration(labelText: 'نوع المادة'),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged:
          (val) => setState(() => materials[index]['material_type'] = val),
    );
  }

  Widget buildCapacityDropdown(int index) {
    final selected = materials[index]['material_type'];
    final capacities = {
      'البودرة الجافة': [
        '2 kg',
        '4 kg',
        '6 kg',
        '9 kg',
        '12 kg',
        '50 kg',
        '100 kg',
      ],
      'ثاني اكسيد الكربون': ['2 kg', '6 kg'],
    };

    if (selected == null || !capacities.containsKey(selected)) {
      return const SizedBox.shrink();
    }

    final value = materials[index]['capacity'];
    final availableOptions = capacities[selected]!;

    final safeValue = availableOptions.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: const InputDecoration(labelText: 'السعة'),
      items:
          availableOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
      onChanged: (val) => setState(() => materials[index]['capacity'] = val),
    );
  }

  Widget buildComponentDropdown(int index, List<String> items) {
    final selected = materials[index]['component_name']?.toString().trim();

    final uniqueItems = items.map((e) => e.trim()).toSet().toList();

    // Force reset if selected value not in current dropdown list
    final safeValue = uniqueItems.contains(selected) ? selected : null;
    if (selected != null && !uniqueItems.contains(selected)) {
      materials[index]['component_name'] = null;
    }

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: const InputDecoration(labelText: 'اسم القطعة'),
      items:
          uniqueItems
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
      onChanged: (val) {
        setState(() {
          materials[index]['component_name'] = val?.trim();
        });
      },
    );
  }

  Future<void> _fetchTechnicianName() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final userData =
        await supabase
            .from('users')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();

    if (userData != null && userData['name'] != null) {
      setState(() {
        technicianName = userData['name'];
      });
    }
  }

  Future<String?> _fetchActionId(Map<String, dynamic> material) async {
    final supabase = Supabase.instance.client;
    print(
      '[🔍] Lookup for action: '
      'name=${material['action_name'] ?? '❌'}, '
      'tool=${material['tool_type'] ?? '❌'}, '
      'material=${material['material_type'] ?? '❌'}, '
      'capacity=${material['capacity'] ?? '❌'}, '
      'component=${material['component_name'] ?? '❌'}',
    );

    final actionName = material['action_name'];
    final toolType =
        (material['tool_type'] == null ||
                material['tool_type'].toString().trim().isEmpty)
            ? 'fire extinguisher'
            : material['tool_type'].toString().trim();
    final materialType = material['material_type'];
    final capacity = material['capacity'];
    final componentName = material['component_name'];

    final query = supabase
        .from('maintenance_prices')
        .select('id')
        .eq('action_name', actionName)
        .eq('tool_type', toolType);

    if (actionName == 'صيانة') {
      if (materialType != null && capacity != null) {
        query.eq('material_type', materialType).eq('capacity', capacity);
      } else {
        return null;
      }
    } else if (actionName == 'تركيب قطع غيار') {
      if (materialType != null && componentName != null) {
        query
            .eq('material_type', materialType)
            .eq('component_name', componentName);
      } else {
        return null;
      }
    } else if (actionName == 'تعبئة') {
      if (materialType != null) {
        query.eq('material_type', materialType);
      } else {
        return null;
      }
    }

    final results = await query.limit(1).select();
    return results.isNotEmpty ? results.first['id'] as String : null;
  }

  Future<void> _loadExportRequest() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response =
        await supabase
            .from('export_requests')
            .select()
            .eq('created_by', user.id)
            .filter('is_approved', 'is', null) // Only unapproved requests
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (response != null) {
      requestId = response['id'];

      final List<dynamic>? toolList = response['tool_codes'];
      final returnDateStr = response['return_date'];

      if (toolList != null) {
        final uniqueMap = <String, Map<String, dynamic>>{};
        for (final item in toolList) {
          final toolName = item['toolName'];
          if (toolName != null && toolName is String && toolName.isNotEmpty) {
            uniqueMap[toolName] = {
              'toolName': toolName,
              'note': item['note'] ?? '',
              'action_name': item['action_name'],
              'material_type': item['material_type'],
              'capacity': item['capacity'],
              'component_name': item['component_name'],
              'filled_amount': item['filled_amount'],
              'tool_type': item['tool_type'] ?? 'fire extinguisher',
            };
          }
        }
        materials = uniqueMap.values.toList();
      }
    }

    setState(() => isLoading = false);
  }

  Future<void> _selectReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        selectedReturnDate = picked;
        _returnDateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  Future<void> _submitAuthorization() async {
    final supabase = Supabase.instance.client;
    //delete
    for (final material in materials) {
      print('🔧 Processing toolName: ${material['toolName']}');
      final actionId = await _fetchActionId(material);
      if (actionId != null) {
        material['action_id'] = actionId;
      } else {
        print('❌ No action ID found for: ${material['toolName']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحديد الإجراء لأداة: ${material['toolName']}'),
          ),
        );
        return;
      }
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in');
      return;
    }

    if (technicianSignature.isEmpty ||
        _returnDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول وتوقيع التصريح')),
      );
      return;
    }
    if (materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة أداة واحدة على الأقل')),
      );
      return;
    }

    try {
      final signatureBytes = await technicianSignature.toPngBytes();
      final signatureBase64 = base64Encode(signatureBytes!);

      final DateTime? parsedReturnDate = selectedReturnDate;
      if (parsedReturnDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار تاريخ الإرجاع')),
        );
        return;
      }

      final payload = {
        'vehicle_owner': technicianName,
        'vehicle_number': _vehicleController.text.trim(),
        'vehicle_type': _vehicleTypeController.text.trim(),
        'return_date': parsedReturnDate.toIso8601String(), // ✅ أهم تعديل هنا
        'material_type': materialType,
        'technician_signature': signatureBase64,
        'tool_codes': materials,
        'usage_reason': materials.map((m) => m['note']).join(' - '),
      };
      for (final material in materials) {
        final actionId = await _fetchActionId(material);
        if (actionId != null) {
          material['action_id'] = actionId;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تعذر تحديد الإجراء لأداة: ${material['toolName']}',
              ),
            ),
          );
          return;
        }
      }

      if (requestId != null) {
        await supabase
            .from('export_requests')
            .update({...payload, 'is_submitted': true})
            .eq('id', requestId!);
      } else {
        await supabase.from('export_requests').insert({
          ...payload,
          'created_by': user.id,
          'created_by_name': technicianName,
          'created_by_role': 'فني السلامة العامة',
          'is_approved': null,
          'is_submitted': true, // ✅ تمت الإرسال فعليًا
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التقرير بنجاح، بانتظار موافقة المدير'),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error during submit: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
    }
  }

  void _addNewMaterial() {
    setState(() {
      materials.add({
        'toolName': '',
        'note': '',
        'action_name': null,
        'tool_type': 'fire extinguisher',
        'material_type': null,
        'capacity': null,
        'component_name': null,
      });
    });
  }

  final Map<String, List<String>> materialOptions = {
    'fire extinguisher': [
      'ثاني اكسيد الكربون',
      'البودرة الجافة',
      'الرغوة (B.C.F)',
      'الماء',
      'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
    ],
  };

  void _removeMaterial(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: const Text('هل أنت متأكد أنك تريد حذف هذه الأداة؟'),
              actions: [
                TextButton(
                  child: const Text('حذف'),
                  onPressed: () => Navigator.pop(context, true),
                ),
                TextButton(
                  child: const Text('إلغاء'),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
    );

    if (confirm == true) {
      setState(() => materials.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat.yMd().format(DateTime.now());
    final dayName = DateFormat.EEEE('ar').format(DateTime.now());

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: const Text(
              'تصريح اخراج مواد',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'جامعة العلوم والتكنولوجيا الاردنية / دائرة السلامة والصحة المهنية والبيئية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'اليوم: $dayName',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'التاريخ: $todayFormatted',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'يسمح للسيد: $technicianName',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vehicleController,
                decoration: const InputDecoration(labelText: 'رقم المركبة'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(labelText: 'نوع المركبة'),
              ),
              const SizedBox(height: 16),
              const Text(
                'بإخراج المواد المبينة أدناه:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              ...materials.asMap().entries.map((entry) {
                final index = entry.key;
                final material = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: material['toolName'],
                          decoration: const InputDecoration(
                            labelText: 'اسم الأداة',
                          ),
                          onChanged: (val) async {
                            materials[index]['toolName'] =
                                val; // Save tool name
                            final toolData =
                                await Supabase.instance.client
                                    .from('safety_tools')
                                    .select(
                                      'material_type, capacity, tool_type',
                                    )
                                    .eq('name', val)
                                    .maybeSingle();

                            if (toolData != null) {
                              setState(() {
                                materials[index]['material_type'] =
                                    toolData['material_type'];
                                materials[index]['capacity'] =
                                    toolData['capacity'];
                                materials[index]['tool_type'] =
                                    toolData['tool_type'];
                              });
                            }
                          },
                        ),
                        TextFormField(
                          initialValue: material['note'],
                          decoration: const InputDecoration(labelText: 'السبب'),
                          onChanged: (val) => materials[index]['note'] = val,
                        ),
                        DropdownButtonFormField<String>(
                          value: material['action_name'],
                          decoration: const InputDecoration(
                            labelText: 'اسم الإجراء',
                          ),
                          items:
                              ['صيانة', 'تركيب قطع غيار', 'تعبئة']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            setState(() {
                              material['action_name'] = val;
                              material['material_type'] = null;
                              material['capacity'] = null;
                              material['component_name'] = null;
                            });
                          },
                        ),
                        if (material['action_name'] == 'صيانة') ...[
                          buildMaterialDropdown(index, [
                            'البودرة الجافة',
                            'ثاني اكسيد الكربون',
                          ]),
                          buildCapacityDropdown(index),
                        ] else if (material['action_name'] == 'تعبئة') ...[
                          buildMaterialDropdown(index, [
                            'ثاني اكسيد الكربون',
                            'البودرة الجافة',
                          ]),
                          TextFormField(
                            initialValue: material['filled_amount']?.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'كمية التعبئة (كغم)',
                            ),
                            onChanged: (val) {
                              setState(() {
                                materials[index]['filled_amount'] =
                                    double.tryParse(val);
                              });
                            },
                          ),
                        ] else if (material['action_name'] ==
                            'تركيب قطع غيار') ...[
                          buildMaterialDropdown(index, [
                            'ثاني اكسيد الكربون',
                            'البودرة الجافة',
                            'الرغوة (B.C.F)',
                            'الماء',
                            'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
                          ]),

                          if (material['material_type'] == 'ثاني اكسيد الكربون')
                            buildComponentDropdown(index, [
                              'محبس طفاية CO2',
                              'خرطوم طفاية حريق',
                              'سلندر خارجي لطفاية الحريق',
                              'ساعة ضغط',
                              'مقبض طفاية الحريق',
                              'قاذف طفاية الحريق',
                              'طقم جلود(كسكيت)',
                            ])
                          else if (material['material_type'] ==
                              'البودرة الجافة')
                            buildComponentDropdown(index, [
                              'متعدد',
                              'خرطوم طفاية حريق',
                              'سلندر خارجي لطفاية الحريق',
                              'ساعة ضغط',
                              'مقبض طفاية الحريق',
                              'قاذف طفاية الحريق',
                              'طقم جلود(كسكيت)',
                            ])
                          else if ([
                            'الرغوة (B.C.F)',
                            'الماء',
                            'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
                          ].contains(material['material_type']))
                            buildComponentDropdown(index, [
                              'خرطوم طفاية حريق',
                              'سلندر خارجي لطفاية الحريق',
                              'ساعة ضغط',
                              'مقبض طفاية الحريق',
                              'قاذف طفاية الحريق',
                              'طقم جلود(كسكيت)',
                            ]),
                        ],

                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => _removeMaterial(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _addNewMaterial,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة أداة جديدة'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: materialType,
                items: const [
                  DropdownMenuItem(
                    value: 'مقتنيات شخصية',
                    child: Text('مقتنيات شخصية'),
                  ),
                  DropdownMenuItem(
                    value: 'مقتنيات جامعية',
                    child: Text('مقتنيات جامعية'),
                  ),
                ],
                onChanged: (value) => setState(() => materialType = value!),
                decoration: const InputDecoration(labelText: 'نوع المواد'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _returnDateController,
                readOnly: true,
                onTap: _selectReturnDate,
                decoration: const InputDecoration(
                  labelText: 'تاريخ إعادة المواد',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اسم الموظف: $technicianName',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text('توقيعه:'),
              Signature(
                controller: technicianSignature,
                height: 100,
                backgroundColor: Colors.grey[200]!,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: agree,
                onChanged: (v) => setState(() => agree = v ?? false),
                title: const Text(
                  'على أن يقوم بإعادتها فور انتهاء العمل المطلوب',
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    print('🧨 BUTTON CLICKED');
                    if (!agree) {
                      print('🚫 User didn’t check the agreement box');
                      return;
                    }
                    _submitAuthorization();
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00408b),
                  ),
                  child: const Text(
                    'إرسال التصريح',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
