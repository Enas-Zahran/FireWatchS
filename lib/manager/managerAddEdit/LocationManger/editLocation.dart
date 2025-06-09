import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';
class EditLocationPage extends StatefulWidget {
  final Map<String, dynamic> location;
  const EditLocationPage({super.key, required this.location});

  @override
  State<EditLocationPage> createState() => _EditLocationPageState();
}

class _EditLocationPageState extends State<EditLocationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location['name']);
    _codeController = TextEditingController(text: widget.location['code']);
  }

  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();

    final existing = await Supabase.instance.client
        .from('locations')
        .select()
        .eq('code', code)
        .neq('id', widget.location['id'])
        .maybeSingle();

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الترميز مستخدم بالفعل.')),
      );
      return;
    }

    await Supabase.instance.client.from('locations').update({
      'name': _nameController.text.trim(),
      'code': code,
    }).eq('id', widget.location['id']);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تعديل المكان بنجاح')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تعديل ${widget.location['name']}', style: const TextStyle(color: Colors.white)),
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
                  onPressed: _updateLocation,
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
