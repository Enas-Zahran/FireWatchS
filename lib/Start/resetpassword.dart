import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class ResetPasswordRequestPage extends StatefulWidget {
  static const String routeName = 'resetPassword';

  @override
  State<ResetPasswordRequestPage> createState() =>
      _ResetPasswordRequestPageState();
}

class _ResetPasswordRequestPageState extends State<ResetPasswordRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          email,
          redirectTo: 'firewatch://reset-password',
        );

        showDialog(
          context: context,
          builder:
              (context) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: Text('تم الإرسال بنجاح'),
                  content: Text(
                    'يرجى التحقق من بريدك الإلكتروني واتباع الرابط لإعادة تعيين كلمة المرور.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('حسناً'),
                    ),
                  ],
                ),
              ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إرسال البريد الإلكتروني: $error')),
        );
      } finally {
        setState(() => _isLoading = false);
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
          title: Text('إعادة تعيين كلمة المرور'),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور:',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _emailController,
                      decoration: customInputDecoration.copyWith(
                        labelText: 'البريد الإلكتروني',
                        hintText: 'username@cit.just.edu.jo',
                      ),
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendResetEmail,
                    child:
                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                              'إرسال الرابط',
                              style: TextStyle(color: Colors.white),
                            ),
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
      ),
    );
  }
}
