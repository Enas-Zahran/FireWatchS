import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:FireWatch/My/InputDecoration.dart';
import 'dart:convert';

class ExportRequestMaterialsPage extends StatefulWidget {
  final String requestId;
  final String technicianName;
  final bool isReadonly;

  const ExportRequestMaterialsPage({
    super.key,
    required this.requestId,
    required this.technicianName,
    this.isReadonly = false,
  });

  @override
  State<ExportRequestMaterialsPage> createState() =>
      _ExportRequestMaterialsPageState();
}

class _ExportRequestMaterialsPageState
    extends State<ExportRequestMaterialsPage> {
  final supabase = Supabase.instance.client;
  final SignatureController managerSignature = SignatureController(
    penStrokeWidth: 2,
  );

  Map<String, dynamic>? request;
  final _vehicleOwnerController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _returnDateController = TextEditingController();
  String materialType = 'مقتنيات شخصية';
  DateTime? returnDate;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequest();
  }

  Widget buildEditableDropdown(
    int index,
    String field,
    List<String> options,
    String label,
  ) {
    final selectedValue =
        request!['tool_codes'][index][field]?.toString().trim();
    final uniqueOptions = options.toSet().toList();

    final safeValue =
        uniqueOptions.contains(selectedValue) ? selectedValue : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(labelText: label),
      items:
          uniqueOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
      onChanged:
          widget.isReadonly
              ? null
              : (val) =>
                  setState(() => request!['tool_codes'][index][field] = val),
    );
  }

  Future<void> _fetchRequest() async {
    try {
      final data =
          await supabase
              .from('export_requests')
              .select()
              .eq('id', widget.requestId)
              .maybeSingle();

      if (data == null) {
        print('❌ No export request found.');
        return;
      }

      final toolList = data['tool_codes'] as List<dynamic>? ?? [];

      for (int i = 0; i < toolList.length; i++) {
        final toolName = toolList[i]['toolName'];
      }

      setState(() {
        request = data;
        _vehicleOwnerController.text = data['vehicle_owner'] ?? '';
        _vehicleNumberController.text = data['vehicle_number'] ?? '';
        _vehicleTypeController.text = data['vehicle_type'] ?? '';
        if (data['return_date'] != null) {
          returnDate = DateTime.tryParse(data['return_date']);
          if (returnDate != null) {
            _returnDateController.text = DateFormat.yMd().format(returnDate!);
          }
        }
        materialType = data['material_type'] ?? 'مقتنيات شخصية';
        loading = false;
      });
    } catch (e) {
      print('❌ Error loading export request: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  List<String> getCapacities(String? materialType) {
    if (materialType == 'البودرة الجافة') {
      return ['2 kg', '4 kg', '6 kg', '9 kg', '12 kg', '50 kg', '100 kg'];
    } else if (materialType == 'ثاني اكسيد الكربون') {
      return ['2 kg', '6 kg'];
    }
    return [];
  }

  Future<Map<String, dynamic>?> _fetchActionInfoForMaterial(
    Map<String, dynamic> material,
  ) async {
    final actionName = material['action_name'];
    if (actionName == null || actionName.toString().isEmpty) {
      print('⚠️ Missing action_name');
      return null;
    }

    final toolType = material['tool_type'] ?? 'fire extinguisher';
    String? materialType = material['material_type']?.toString().trim();
    final capacity = material['capacity'];
    final componentName = material['component_name'];
    final toolName = material['toolName'];

    if ((materialType == null || materialType.isEmpty) && toolName != null) {
      final tool =
          await supabase
              .from('safety_tools')
              .select('material_type')
              .eq('name', toolName)
              .maybeSingle();
      materialType = tool?['material_type'];
    }

    final query = supabase
        .from('maintenance_prices')
        .select('id, price')
        .eq('action_name', actionName)
        .eq('tool_type', toolType);

    if (actionName == 'صيانة') {
      if (materialType == null || capacity == null) {
        print('⚠️ صيانة requires material_type and capacity');
        return null;
      }
      query.eq('material_type', materialType).eq('capacity', capacity);
    } else if (actionName == 'تركيب قطع غيار') {
      if (materialType == null || componentName == null) {
        print('⚠️ تركيب requires material_type and component_name');
        return null;
      }
      query
          .eq('material_type', materialType)
          .eq('component_name', componentName);
    } else if (actionName == 'تعبئة') {
      if (materialType == null) {
        print('⚠️ تعبئة requires material_type');
        return null;
      }
      query.eq('material_type', materialType);
    }

    final results = await query.limit(1).select();
    return results.isEmpty ? null : results.first;
  }

  Future<void> _approveRequest() async {
    if (managerSignature.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب توقيع المدير لاعتماد الطلب')),
      );
      return;
    }

    final signatureBytes = await managerSignature.toPngBytes();
    if (signatureBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطأ في توقيع المدير')));
      return;
    }

    final existing =
        await supabase
            .from('export_requests')
            .select('id, created_by')
            .eq('id', widget.requestId)
            .maybeSingle();
    if (existing == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الطلب غير موجود')));
      return;
    }

    final toolList = request?['tool_codes'] as List<dynamic>? ?? [];
    for (final material in toolList) {
      try {
        final toolName = material['toolName']?.toString().trim();
        if (toolName == null || toolName.isEmpty) continue;

        final actionInfo = await _fetchActionInfoForMaterial(material);
        if (actionInfo == null) {
          material['is_matching'] = false;
          continue;
        }

        material['action_id'] = actionInfo['id'];
        double price = (actionInfo['price'] as num).toDouble();
        if (material['action_name'] == 'تعبئة') {
          final filledAmount =
              double.tryParse(material['filled_amount']?.toString() ?? '') ??
              0.0;
          price *= filledAmount;
        }
        material['price'] = price;
        material['is_matching'] = true;

        await supabase.from('tool_action_logs').insert({
          'tool_name': toolName,
          'action_id': material['action_id'],
          'price': price,
          'performed_at': DateTime.now().toIso8601String(),
          'technician_id': existing['created_by'],
          'notes': material['note'],
        });
      } catch (e, stack) {
        print('❌ Error: $e');
      }
    }

    await supabase
        .from('export_requests')
        .update({
          'vehicle_owner': _vehicleOwnerController.text.trim(),
          'vehicle_number': _vehicleNumberController.text.trim(),
          'vehicle_type': _vehicleTypeController.text.trim(),
          'return_date': (returnDate ?? DateTime.now()).toIso8601String(),
          'material_type': materialType,
          'is_approved': true,
          'manager_signature': base64Encode(signatureBytes),
          'approved_at': DateTime.now().toIso8601String(),
          'tool_codes': toolList,
        })
        .eq('id', widget.requestId);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اعتماد الطلب وتسجيل الإجراءات بنجاح')),
      );
    }
  }

  Future<void> _pickReturnDate() async {
    if (widget.isReadonly) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        returnDate = picked;
        _returnDateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  Future<void> _rejectRequest() async {
    print('Rejecting requestId: ${widget.requestId}');

    if (managerSignature.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب توقيع المدير لرفض الطلب')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد الرفض'),
              content: const Text('هل أنت متأكد أنك تريد رفض هذا الطلب؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('رفض'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ),
    );

    if (confirm != true) return;

    final signatureBytes = await managerSignature.toPngBytes();
    if (signatureBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطأ في توقيع المدير')));
      return;
    }

    await supabase
        .from('export_requests')
        .update({
          'is_approved': false,
          'manager_signature': base64Encode(signatureBytes),
          'rejected_at': DateTime.now().toIso8601String(),
        })
        .eq('id', widget.requestId);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم رفض الطلب بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat.yMd().format(DateTime.now());
    final dayName = DateFormat.EEEE('ar').format(DateTime.now());

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'تفاصيل طلب الإخراج',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'جامعة العلوم والتكنولوجيا الأردنية / دائرة السلامة والصحة المهنية والبيئية',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
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
                        'اسم الموظف: ${widget.technicianName}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vehicleOwnerController,
                        decoration: customInputDecoration.copyWith(
                          labelText: 'اسم السائق',
                        ),
                        enabled: !widget.isReadonly,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _vehicleNumberController,
                        decoration: customInputDecoration.copyWith(
                          labelText: 'رقم المركبة',
                        ),
                        enabled: !widget.isReadonly,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _vehicleTypeController,
                        decoration: customInputDecoration.copyWith(
                          labelText: 'نوع المركبة',
                        ),
                        enabled: !widget.isReadonly,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: materialType,
                        decoration: customInputDecoration.copyWith(
                          labelText: 'نوع المواد',
                        ),
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
                        onChanged:
                            widget.isReadonly
                                ? null
                                : (val) => setState(() => materialType = val!),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _returnDateController,
                        readOnly: true,
                        onTap: _pickReturnDate,
                        decoration: customInputDecoration.copyWith(
                          labelText: 'تاريخ الإرجاع',
                        ),
                        enabled: !widget.isReadonly,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'المواد المطلوبة:',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      ...(request?['tool_codes'] as List<dynamic>? ?? []).asMap().entries.map((
                        entry,
                      ) {
                        final i = entry.key;
                        final item = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                TextFormField(
                                  initialValue: item['toolName'],
                                  readOnly: widget.isReadonly,
                                  decoration: const InputDecoration(
                                    labelText: 'اسم الأداة',
                                  ),
                                  onChanged:
                                      widget.isReadonly
                                          ? null
                                          : (val) {
                                            setState(() {
                                              request!['tool_codes'][i]['toolName'] =
                                                  val;
                                            });
                                          },
                                ),

                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: item['note'],
                                  readOnly: widget.isReadonly,
                                  decoration: const InputDecoration(
                                    labelText: 'السبب',
                                  ),
                                  onChanged:
                                      widget.isReadonly
                                          ? null
                                          : (val) {
                                            request!['tool_codes'][i]['note'] =
                                                val;
                                          },
                                ),
                                DropdownButtonFormField<String>(
                                  value: item['action_name'],
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
                                  onChanged:
                                      widget.isReadonly
                                          ? null
                                          : (val) {
                                            setState(() {
                                              request!['tool_codes'][i]['action_name'] =
                                                  val;
                                              request!['tool_codes'][i]['material_type'] =
                                                  null;
                                              request!['tool_codes'][i]['capacity'] =
                                                  null;
                                              request!['tool_codes'][i]['component_name'] =
                                                  null;
                                            });
                                          },
                                ),
                                if (item['action_name'] == 'صيانة') ...[
                                  buildEditableDropdown(i, 'material_type', [
                                    'البودرة الجافة',
                                    'ثاني اكسيد الكربون',
                                  ], 'نوع المادة'),
                                  if ([
                                    'البودرة الجافة',
                                    'ثاني اكسيد الكربون',
                                  ].contains(item['material_type']))
                                    buildEditableDropdown(
                                      i,
                                      'capacity',
                                      getCapacities(item['material_type']),
                                      'السعة',
                                    ),
                                ],

                                if (item['action_name'] == 'تعبئة') ...[
                                  buildEditableDropdown(i, 'material_type', [
                                    'ثاني اكسيد الكربون',
                                    'البودرة الجافة',
                                  ], 'نوع المادة'),
                                  TextFormField(
                                    initialValue:
                                        item['filled_amount']?.toString(),
                                    readOnly: widget.isReadonly,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'كمية التعبئة (كغم)',
                                    ),
                                    onChanged:
                                        widget.isReadonly
                                            ? null
                                            : (val) =>
                                                request!['tool_codes'][i]['filled_amount'] =
                                                    val,
                                  ),
                                ],

                                if (item['action_name'] ==
                                    'تركيب قطع غيار') ...[
                                  buildEditableDropdown(i, 'material_type', [
                                    'ثاني اكسيد الكربون',
                                    'البودرة الجافة',
                                    'الرغوة (B.C.F)',
                                    'الماء',
                                    'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
                                  ], 'نوع المادة'),

                                  if (item['material_type'] ==
                                      'ثاني اكسيد الكربون')
                                    buildEditableDropdown(i, 'component_name', [
                                      'محبس طفاية CO2',
                                    ], 'اسم القطعة')
                                  else if (item['material_type'] ==
                                      'البودرة الجافة')
                                    Builder(
                                      builder: (_) {
                                        final uniqueComponents =
                                            [
                                              'متعدد',
                                              'خرطوم طفاية حريق',
                                              'سلندر خارجي لطفاية الحريق',
                                              'ساعة ضغط',
                                              'مقبض طفاية الحريق',
                                              'قاذف طفاية الحريق',
                                              'طقم جلود(كسكيت)',
                                            ].toSet().toList();

                                        final selectedValue =
                                            request!['tool_codes'][i]['component_name']
                                                ?.toString()
                                                .trim();

                                        if (!uniqueComponents.contains(
                                          selectedValue,
                                        )) {
                                          request!['tool_codes'][i]['component_name'] =
                                              null;
                                        }

                                        return buildEditableDropdown(
                                          i,
                                          'component_name',
                                          uniqueComponents,
                                          'اسم القطعة',
                                        );
                                      },
                                    )
                                  else if ([
                                    'الرغوة (B.C.F)',
                                    'الماء',
                                    'البودرة الجافة ذات مستشعر حرارة الاوتامتيكي',
                                  ].contains(item['material_type']))
                                    Builder(
                                      builder: (_) {
                                        final uniqueComponents =
                                            [
                                              'متعدد',
                                              'خرطوم طفاية حريق',
                                              'سلندر خارجي لطفاية الحريق',
                                              'ساعة ضغط',
                                              'مقبض طفاية الحريق',
                                              'قاذف طفاية الحريق',
                                              'طقم جلود(كسكيت)',
                                            ].toSet().toList();

                                        final selectedValue =
                                            request!['tool_codes'][i]['component_name']
                                                ?.toString()
                                                .trim();

                                        if (!uniqueComponents.contains(
                                          selectedValue,
                                        )) {
                                          request!['tool_codes'][i]['component_name'] =
                                              null;
                                        }

                                        return buildEditableDropdown(
                                          i,
                                          'component_name',
                                          uniqueComponents,
                                          'اسم القطعة',
                                        );
                                      },
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      const Text(
                        'توقيع الموظف:',
                        style: TextStyle(fontSize: 16),
                      ),
                      if (request?['technician_signature'] != null)
                        Image.memory(
                          base64Decode(request!['technician_signature']),
                          height: 100,
                          fit: BoxFit.contain,
                        )
                      else
                        const Text(
                          'لا يوجد توقيع',
                          style: TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'توقيع المدير:',
                        style: TextStyle(fontSize: 16),
                      ),
                      widget.isReadonly
                          ? (request?['manager_signature'] != null
                              ? Image.memory(
                                base64Decode(request!['manager_signature']),
                                height: 100,
                                fit: BoxFit.contain,
                              )
                              : const Text(
                                'لا يوجد توقيع مدير',
                                style: TextStyle(color: Colors.red),
                              ))
                          : Signature(
                            controller: managerSignature,
                            height: 100,
                            backgroundColor: Colors.grey[200]!,
                          ),
                      const SizedBox(height: 20),
                      if (!widget.isReadonly)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _approveRequest,
                              icon: const Icon(Icons.check),
                              label: const Text('اعتماد الطلب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff00408b),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _rejectRequest,
                              icon: const Icon(Icons.close),
                              label: const Text('رفض الطلب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
