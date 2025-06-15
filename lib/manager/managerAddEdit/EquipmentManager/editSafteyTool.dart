import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class EditSafetyToolPage extends StatefulWidget {
  final Map<String, dynamic> tool;

  const EditSafetyToolPage({Key? key, required this.tool}) : super(key: key);

  @override
  _EditSafetyToolPageState createState() => _EditSafetyToolPageState();
}

class _EditSafetyToolPageState extends State<EditSafetyToolPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedType;
  String? _selectedMaterial;
  String? _selectedCapacity;
  DateTime? _purchaseDate;

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

  @override
  void initState() {
    super.initState();
    final tool = widget.tool;
    _nameController.text = tool['name'] ?? '';
    _selectedType = tool['type'];
    _selectedMaterial = tool['material_type'];
    _selectedCapacity = tool['capacity'];
    _purchaseDate = DateTime.tryParse(tool['purchase_date'] ?? '');
  }

  Future<void> _updateTool() async {
    if (!_formKey.currentState!.validate() || _purchaseDate == null) return;

    final nextMaintenanceDate = DateTime(
      _purchaseDate!.year + 1,
      _purchaseDate!.month,
      _purchaseDate!.day,
    );

    await Supabase.instance.client
        .from('safety_tools')
        .update({
          'name': _nameController.text.trim(),
          'type': _selectedType,
          'material_type': _selectedMaterial,
          'capacity': _selectedCapacity,
          'purchase_date': _purchaseDate!.toIso8601String(),
          'next_maintenance_date': nextMaintenanceDate.toIso8601String(),
        })
        .eq('id', widget.tool['id']);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعديل الأداة بنجاح')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(child: Text('تعديل أداة سلامة', style: TextStyle(color: Colors.white))),
          iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildTextField('اسم الأداة', _nameController),
                    const SizedBox(height: 12),
                    buildDropdown(
                      label: 'نوع أداة السلامة',
                      value: _selectedType,
                      items: materialOptions.keys.toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedType = val;
                          _selectedMaterial = null;
                          _selectedCapacity = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_selectedType != null)
                      buildDropdown(
                        label: 'نوع المادة',
                        value: _selectedMaterial,
                        items: materialOptions[_selectedType!]!,
                        onChanged: (val) {
                          setState(() {
                            _selectedMaterial = val;
                            _selectedCapacity = null;
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                    if (_selectedMaterial != null)
                      buildDropdown(
                        label: 'السعة',
                        value: _selectedCapacity,
                        items: capacityOptions[_selectedMaterial!]!,
                        onChanged: (val) {
                          setState(() => _selectedCapacity = val);
                        },
                      ),
                    const SizedBox(height: 12),
                    ListTile(
                      tileColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      title: Text(
                        _purchaseDate == null
                            ? 'اختر تاريخ الشراء'
                            : DateFormat('yyyy-MM-dd').format(_purchaseDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _purchaseDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _purchaseDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updateTool,
                      child: const Text('تعديل', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(400, 50),
                        backgroundColor: const Color(0xff00408b),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return SizedBox(
      width: 400,
      child: TextFormField(
        controller: controller,
        decoration: customInputDecoration.copyWith(
          labelText: label,
          hintText: 'أدخل $label',
        ),
        validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال $label' : null,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 400,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: customInputDecoration.copyWith(labelText: label),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? 'يرجى اختيار $label' : null,
      ),
    );
  }
}
