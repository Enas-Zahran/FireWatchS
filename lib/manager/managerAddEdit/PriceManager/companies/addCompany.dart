// --- تنفيذ صفحة إضافة الشركة المنفذة بناءً على جدول contract_companies ---

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class AddExecutingCompanyPage extends StatefulWidget {
  const AddExecutingCompanyPage({super.key});

  @override
  State<AddExecutingCompanyPage> createState() => _AddExecutingCompanyPageState();
}

class _AddExecutingCompanyPageState extends State<AddExecutingCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _signDate;

  Future<void> _addCompany() async {
    if (!_formKey.currentState!.validate() || _signDate == null) return;

    final endDate = DateTime(_signDate!.year + 1, _signDate!.month, _signDate!.day);

    // التحقق من عدم وجود شركة بنفس السنة
    final existing = await Supabase.instance.client
        .from('contract_companies')
        .select()
        .gte('contract_start_date', DateTime(_signDate!.year, 1, 1).toIso8601String())
        .lte('contract_start_date', DateTime(_signDate!.year, 12, 31).toIso8601String())
        .maybeSingle();

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يوجد بالفعل شركة منفذة لهذه السنة.')),
      );
      return;
    }

    await Supabase.instance.client.from('contract_companies').insert({
      'company_name': _nameController.text.trim(),
      'contract_start_date': _signDate!.toIso8601String(),
      'contract_end_date': endDate.toIso8601String(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافة الشركة بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('إضافة الشركة المنفذة', style: TextStyle(color: Colors.white))),
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
                decoration: customInputDecoration.copyWith(
                  labelText: 'اسم الشركة',
                  
                  hintText: 'أدخل اسم الشركة',
                  alignLabelWithHint: true,
                ),
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
                    initialDate: DateTime.now(),
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
                onPressed: _addCompany,
                child: const Text('إضافة', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff00408b),
                  minimumSize: const Size(400, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
