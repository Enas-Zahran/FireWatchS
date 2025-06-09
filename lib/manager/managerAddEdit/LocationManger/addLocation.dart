import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  Future<void> _addLocation() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();

    final existing = await Supabase.instance.client
        .from('locations')
        .select()
        .eq('code', code)
        .maybeSingle();

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الترميز مستخدم بالفعل.')),
      );
      return;
    }

    await Supabase.instance.client.from('locations').insert({
      'name': _nameController.text.trim(),
      'code': code,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة المكان بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('إضافة مكان', style: TextStyle(color: Colors.white))),
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
                    labelText: 'اسم المكان',
                    hintText: 'أدخل اسم المكان',
                    alignLabelWithHint: true,
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم المكان' : null,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _codeController,
                  decoration: customInputDecoration.copyWith(
                    labelText: 'ترميز المكان',
                    hintText: 'أدخل ترميز المكان',
                    alignLabelWithHint: true,
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال ترميز المكان' : null,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _addLocation,
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
      ),
    );
  }
}
