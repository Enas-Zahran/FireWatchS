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
    return DropdownButtonFormField<String>(
      value: request!['tool_codes'][index][field],
      decoration: InputDecoration(labelText: label),
      items:
          options
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
    final data =
        await supabase
            .from('export_requests')
            .select()
            .eq('id', widget.requestId)
            .maybeSingle();
    if (data != null) {
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
    }
  }

  Future<double> _fetchPriceForMaterial(Map<String, dynamic> material) async {
    final actionName = material['action_name'];
    final materialType = material['material_type'];
    final capacity = material['capacity'];
    final componentName = material['component_name'];

    final query = supabase
        .from('maintenance_prices')
        .select('price')
        .eq('action_name', actionName);
    if (materialType != null) query.eq('material_type', materialType);
    if (capacity != null) query.eq('capacity', capacity);
    if (componentName != null) query.eq('component_name', componentName);

    final result = await query.maybeSingle();
    if (result != null && result['price'] != null) {
      return result['price'] is int
          ? (result['price'] as int).toDouble()
          : result['price'];
    }
    return 0.0;
  }

  Future<void> _approveRequest() async {
    print('🔧 Starting approval process...');

    if (managerSignature.isEmpty) {
      print('❌ Manager signature is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب توقيع المدير لاعتماد الطلب')),
      );
      return;
    }

    final signatureBytes = await managerSignature.toPngBytes();
    if (signatureBytes == null) {
      print('❌ Failed to convert manager signature to PNG bytes');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('خطأ في توقيع المدير')));
      return;
    }

    final toolList = request?['tool_codes'] as List<dynamic>? ?? [];
    print('📦 Found ${toolList.length} materials to process');

    for (final material in toolList) {
      final toolName = material['toolName'];
      print('🔍 Processing tool: $toolName');

      final price = await _fetchPriceForMaterial(material);
      material['price'] = price;
      print('💰 Price for $toolName is $price');

      if (toolName != null && toolName.toString().trim().isNotEmpty) {
        final updateResponse = await supabase
            .from('safety_tools')
            .update({'actions_cost': price})
            .eq('name', toolName);

        print('🛠 Updated actions_cost for $toolName: $updateResponse');
      } else {
        print('⚠️ Skipped tool with empty name');
      }
    }
 print('🧪 Final tool_codes to send: ${jsonEncode(toolList)}');
    final updateExport = await supabase
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
    print('✅ Export request updated: $updateExport');
    print('🧾 Final tool list: ${jsonEncode(toolList)}');
    print(jsonEncode(toolList)); // هل يطبع شكل JSON سليم؟

    print('✅ Export request updated: $updateExport');

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم اعتماد الطلب وتحديث سعر الإجراء بنجاح')),
    );
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
                                            request!['tool_codes'][i]['toolName'] =
                                                val;
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
                                      item['material_type'] == 'البودرة الجافة'
                                          ? [
                                            '2',
                                            '4',
                                            '6',
                                            '9',
                                            '12',
                                            '50',
                                            '100',
                                          ]
                                          : ['2', '6'],
                                      'السعة',
                                    ),
                                ],

                                if (item['action_name'] == 'تعبئة') ...[
                                  buildEditableDropdown(i, 'material_type', [
                                    'ثاني اكسيد الكربون',
                                    'البودرة الجافة',
                                  ], 'نوع المادة'),
                                ],

                                if (item['action_name'] ==
                                    'تركيب قطع غيار') ...[
                                  buildEditableDropdown(i, 'material_type', [
                                    'ثاني اكسيد الكربون',
                                    'البودرة الجافة',
                                    'جميع انواع الطفايات',
                                  ], 'نوع المادة'),
                                  if (item['material_type'] ==
                                      'ثاني اكسيد الكربون')
                                    buildEditableDropdown(i, 'component_name', [
                                      'محبس طفاية CO2',
                                    ], 'اسم القطعة')
                                  else if (item['material_type'] ==
                                      'البودرة الجافة')
                                    buildEditableDropdown(i, 'component_name', [
                                      'سعر رأس الطفاية كامل لطفاية البودرة مع المقبض و الخرطوم و السيفون الداخلي و ساعة الضغط و مسمار الأمان',
                                    ], 'اسم القطعة')
                                  else if (item['material_type'] ==
                                      'جميع انواع الطفايات')
                                    buildEditableDropdown(i, 'component_name', [
                                      'خرطوم طفاية حريق',
                                      'سلندر خارجي لطفاية الحريق',
                                      'ساعة ضغط',
                                      'مقبض طفاية الحريق',
                                      'قاذف طفاية الحريق',
                                      'طقم جلود(كسكيت)',
                                    ], 'اسم القطعة'),
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
