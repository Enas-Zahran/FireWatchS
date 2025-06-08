import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class EditUserPage extends StatefulWidget {
  final String userId;

  const EditUserPage({super.key, required this.userId});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedRole;
  bool _loading = true;

  final List<String> roles = ['المدير', 'فني السلامة العامة', 'رئيس الشعبة'];

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final userData = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', widget.userId)
        .maybeSingle();

    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على المستخدم')),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _nameController.text = userData['name'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _selectedRole = userData['role'];
      _loading = false;
    });
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 🔐 Prevent assigning more than one manager
        if (_selectedRole == 'المدير') {
          final existingAdmin = await Supabase.instance.client
              .from('users')
              .select()
              .eq('role', 'المدير')
              .neq('id', widget.userId)
              .maybeSingle();

          if (existingAdmin != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لا يمكن تعيين مدير جديد. يوجد مدير بالفعل.'),
              ),
            );
            return;
          }
        }

        await Supabase.instance.client
            .from('users')
            .update({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'role': _selectedRole,
            })
            .eq('id', widget.userId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل الحساب بنجاح')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التعديل: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
              child: Text(
            'تعديل المستخدم',
            style: TextStyle(color: Colors.white),
          )),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 400,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: customInputDecoration.copyWith(
                              labelText: 'الاسم',
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'الرجاء إدخال الاسم' : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 400,
                          child: TextFormField(
                            controller: _emailController,
                            decoration: customInputDecoration.copyWith(
                              labelText: 'البريد الإلكتروني',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'الرجاء إدخال البريد';
                              }
                              if (!val.contains('@') ||
                                  !val.endsWith('@cit.just.edu.jo')) {
                                return 'البريد يجب أن ينتهي بـ @cit.just.edu.jo';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 400,
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: customInputDecoration.copyWith(
                              labelText: 'الدور',
                            ),
                            items: roles.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedRole = val),
                            validator: (val) =>
                                val == null ? 'اختر دور المستخدم' : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _updateUser,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(400, 50),
                            backgroundColor: const Color(0xff00408b),
                          ),
                          child: const Text(
                            'تعديل الحساب',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
