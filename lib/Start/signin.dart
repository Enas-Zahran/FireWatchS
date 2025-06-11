// import 'package:FireWatch/Start/resetpassword.dart';
import 'package:FireWatch/Start/signup.dart';
import 'package:FireWatch/head/headdashboard.dart';
import 'package:FireWatch/manager/managerdashboard.dart';
import 'package:FireWatch/technician/techniciandashboard.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';
import 'package:FireWatch/Start/startPage.dart';

class SignInPage extends StatefulWidget {
  static const String signinRoute = 'signin';

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = response.user;

        if (user != null) {
          // Fetch role and approval status from 'users' table
          final profileData =
              await Supabase.instance.client
                  .from('users')
                  .select('role, is_approved')
                  .eq('id', user.id)
                  .single();

          final role = profileData['role'] as String?;
          final isApproved = profileData['is_approved'] as bool?;

          if (isApproved != true) {
            await Supabase.instance.client.auth.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'لم تتم الموافقة على حسابك بعد. الرجاء انتظار موافقة المدير.',
                ),
              ),
            );
            return;
          }

          if (role != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('تم تسجيل الدخول بنجاح')));

            if (role == 'المدير') {
              Navigator.pushReplacementNamed(
                context,
                ManagerDashboard.managerDashboardRoute,
              );
            } else if (role == 'فني السلامة العامة') {
              Navigator.pushReplacementNamed(
                context,
                TechnicianDashboardPage.routeName,
              );
            } else if (role == 'رئيس الشعبة') {
              Navigator.pushReplacementNamed(
                context,
                Headdashboard.headdashboardRoute,
              );
            } else {
              Navigator.pushReplacementNamed(context, StartPage.startpageRoute);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('لم يتم العثور على دور المستخدم')),
            );
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('فشل تسجيل الدخول')));
        }
      } on AuthException catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ غير متوقع: $e')));
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
            child: Text('تسجيل الدخول', style: TextStyle(color: Colors.white)),
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
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _emailController,
                        decoration: customInputDecoration.copyWith(
                          labelText: 'البريد الإلكتروني',
                          hintText: 'مثال: username@cit.just.edu.jo',
                          floatingLabelAlignment: FloatingLabelAlignment.start,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textAlign: TextAlign.right,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال البريد الإلكتروني';
                          } else if (!RegExp(
                            r'^[\w-]+@cit\.just\.edu\.jo$',
                          ).hasMatch(value)) {
                            return 'يجب أن يكون البريد الإلكتروني بصيغة username@cit.just.edu.jo';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: 400,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        obscuringCharacter: '*',
                        decoration: customInputDecoration.copyWith(
                          labelText: 'كلمة المرور',
                          floatingLabelAlignment: FloatingLabelAlignment.start,
                          prefixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Color(0xff00408b),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        textAlign: TextAlign.right,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كلمة المرور';
                          } else if (value.length < 8) {
                            return 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signIn,
                      child: Text(
                        'تسجيل الدخول',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(400, 50),
                        backgroundColor: Color(0xff00408b),
                      ),
                    ),
                    SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'هل نسيت كلمة المرور؟',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder:
                              //         (context) => ResetPasswordRequestPage(),
                              //   ),
                              // );
                            },
                            child: Text(
                              'اعادة تعيين كلمة السر',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 50.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                SignUpPage.signupRoute,
                              );
                            },
                            child: Text(
                              'إنشاء حساب جديد',
                              style: theme.textTheme.bodyMedium?.copyWith(
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
}
