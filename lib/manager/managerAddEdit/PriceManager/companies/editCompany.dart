// --- صفحة تعديل بيانات الشركة المنفذة ---

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class EditExecutingCompanyPage extends StatefulWidget {
  final Map<String, dynamic> company;

  const EditExecutingCompanyPage({super.key, required this.company});

  @override
  State<EditExecutingCompanyPage> createState() => _EditExecutingCompanyPageState();
}

class _EditExecutingCompanyPageState extends State<EditExecutingCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime? _signDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company['company_name']);
    _signDate = DateTime.tryParse(widget.company['contract_start_date']);
  }

  Future<void> _updateCompany() async {
    if (!_formKey.currentState!.validate() || _signDate == null) return;

    final endDate = DateTime(_signDate!.year + 1, _signDate!.month, _signDate!.day);

    await Supabase.instance.client.from('contract_companies').update({
      'company_name': _nameController.text.trim(),
      'contract_start_date': _signDate!.toIso8601String(),
      'contract_end_date': endDate.toIso8601String(),
    }).eq('id', widget.company['id']);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعديل بيانات الشركة بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('تعديل الشركة المنفذة', style: TextStyle(color: Colors.white))),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: customInputDecoration.copyWith(labelText: 'اسم الشركة'),
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم الشركة' : null,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 20),
                ListTile(
                  tileColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  title: Text(
                    _signDate == null
                        ? 'اختر تاريخ توقيع العقد'
                        : DateFormat('yyyy-MM-dd').format(_signDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _signDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _signDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _updateCompany,
                  child: const Text('تعديل', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00408b),
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
