import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/Start/signin.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class SignUpPage extends StatefulWidget {
  static const String signupRoute = 'signup';

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedRole;

  final List<String> _roles = ['فني السلامة العامة', 'المدير', 'رئيس الشعبة'];

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final role = _selectedRole;

      try {
        if (role == 'المدير') {
          final existingAdmin =
              await Supabase.instance.client
                  .from('users')
                  .select()
                  .eq('role', 'المدير')
                  .maybeSingle();

          if (existingAdmin != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'يوجد بالفعل حساب مدير. لا يمكن إنشاء أكثر من حساب مدير.',
                ),
              ),
            );
            return;
          }
        }

        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        final user = response.user;
        if (user != null) {
          await Supabase.instance.client.from('users').insert({
            'id': user.id,
            'name': name,
            'email': email,
            'role': role,
            'created_at': DateTime.now().toIso8601String(),
            'is_approved': role == 'المدير' ? true : false,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                role == 'المدير'
                    ? 'تم إنشاء حساب المدير بنجاح'
                    : 'تم إرسال طلب إنشاء الحساب بانتظار الموافقة',
              ),
            ),
          );

          _formKey.currentState?.reset();
          setState(() => _selectedRole = null);
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إنشاء الحساب: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff00408b),
          title: Center(
            child: Text('إنشاء حساب', style: TextStyle(color: Colors.white)),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildField('الاسم', _nameController, theme),
                    SizedBox(height: 12),
                    buildEmailField(),
                    SizedBox(height: 12),
                    buildPasswordField(),
                    SizedBox(height: 12),
                    buildConfirmPasswordField(),
                    SizedBox(height: 12),
                    buildRoleDropdown(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signUp,
                      child: Text(
                        'إنشاء الحساب',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(400, 50),
                        backgroundColor: Color(0xff00408b),
                      ),
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'لديك حساب؟',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                SignInPage.signinRoute,
                              );
                            },
                            child: Text(
                              'تسجيل الدخول',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

  Widget buildField(
    String label,
    TextEditingController controller,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 400.0,
      child: TextFormField(
        controller: controller,
        decoration: customInputDecoration.copyWith(
          labelText: label,
          hintText: 'ادخل $label',
          floatingLabelAlignment: FloatingLabelAlignment.start,
        ),
        validator:
            (value) =>
                (value == null || value.isEmpty) ? 'الرجاء إدخال $label' : null,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget buildEmailField() {
    return SizedBox(
      width: 400.0,
      child: TextFormField(
        controller: _emailController,
        decoration: customInputDecoration.copyWith(
          labelText: 'البريد الإلكتروني',
          hintText: 'مثال: username@cit.just.edu.jo',
          floatingLabelAlignment: FloatingLabelAlignment.start,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء إدخال البريد الإلكتروني';
          } else if (!RegExp(r'^[\w-]+@cit\.just\.edu\.jo$').hasMatch(value)) {
            return 'يجب أن يكون البريد الإلكتروني بصيغة username@cit.just.edu.jo';
          }
          return null;
        },
        keyboardType: TextInputType.emailAddress,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget buildPasswordField() {
    return SizedBox(
      width: 400.0,
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        obscuringCharacter: '*',
        decoration: customInputDecoration.copyWith(
          labelText: 'كلمة المرور',
          hintText: 'يجب أن تحتوي على 8 أحرف على الأقل',
          floatingLabelAlignment: FloatingLabelAlignment.start,
          prefixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Color(0xff00408b),
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء إدخال كلمة المرور';
          } else if (value.length < 8) {
            return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
          }
          return null;
        },
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget buildConfirmPasswordField() {
    return SizedBox(
      width: 400.0,
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: !_isConfirmPasswordVisible,
        obscuringCharacter: '*',
        decoration: customInputDecoration.copyWith(
          labelText: 'تأكيد كلمة المرور',
          hintText: 'أعد إدخال كلمة المرور',
          floatingLabelAlignment: FloatingLabelAlignment.start,
          prefixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: Color(0xff00408b),
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value != _passwordController.text) {
            return 'كلمتا المرور غير متطابقتين';
          }
          return null;
        },
        textAlign: TextAlign.right,
        keyboardType: TextInputType.visiblePassword,
        autocorrect: false,
        enableSuggestions: false,
      ),
    );
  }

  Widget buildRoleDropdown() {
    return SizedBox(
      width: 400.0,
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: customInputDecoration.copyWith(
          labelText: 'الدور',
          floatingLabelAlignment: FloatingLabelAlignment.start,
        ),
        items:
            _roles.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(role),
                ),
              );
            }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRole = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'الرجاء اختيار الدور';
          }
          return null;
        },
        dropdownColor: Colors.white,
        isExpanded: true,
        style: TextStyle(color: Colors.black),
        iconEnabledColor: const Color(0xff00408b),
      ),
    );
  }
}
