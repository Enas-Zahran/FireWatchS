import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class UserApprovalDetailPage extends StatefulWidget {
  final String userId;

  const UserApprovalDetailPage({super.key, required this.userId});

  @override
  State<UserApprovalDetailPage> createState() => _UserApprovalDetailPageState();
}

class _UserApprovalDetailPageState extends State<UserApprovalDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedRole;

  bool _loading = true;

  final List<String> roles = ['المدير', 'فني السلامة العامة', 'رئيس الشعبة'];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', widget.userId)
          .maybeSingle();

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المستخدم غير موجود')),
        );
        Navigator.pop(context);
        return;
      }

      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _selectedRole = data['role'];
        _loading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل البيانات: $e')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _approveUser() async {
    if (_formKey.currentState!.validate()) {
      // 🛡 Prevent multiple approved managers
      if (_selectedRole == 'المدير') {
        final existingAdmin = await Supabase.instance.client
            .from('users')
            .select()
            .eq('role', 'المدير')
            .eq('is_approved', true)
            .neq('id', widget.userId)
            .maybeSingle();

        if (existingAdmin != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يوجد بالفعل مدير معتمد')),
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
            'is_approved': true,
          })
          .eq('id', widget.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث وموافقة الحساب بنجاح')),
      );

      Navigator.of(context).pop(true); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('عرض طلب ${_nameController.text}',style: TextStyle(color: Colors.white),)),
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
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,

                  
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
                          validator: (val) =>
                              val == null || val.isEmpty ? 'الرجاء إدخال البريد' : null,
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
                        onPressed: _approveUser,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(400, 50),
                          backgroundColor: const Color(0xff00408b),
                        ),
                        child: const Text(
                          'تأكيد التعديلات والموافقة',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ));
  }
}
