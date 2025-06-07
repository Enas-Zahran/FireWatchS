// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../My/InputDecoration.dart';
// import 'package:FireWatch/Start/signin.dart';

// class ChangePasswordPage extends StatefulWidget {
//   static const String routeName = '/reset-password';

//   @override
//   _ChangePasswordPageState createState() => _ChangePasswordPageState();
// }

// class _ChangePasswordPageState extends State<ChangePasswordPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _passwordController = TextEditingController();
//   String? _token;
//   bool _verifying = true;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final args = ModalRoute.of(context)?.settings.arguments as Map?;
//     _token = args?['token'];

//     // Optionally verify token here (if not already done in main)
//     if (_token != null) {
//       _verifyToken(_token!);
//     } else {
//       setState(() => _verifying = false); // No token — proceed anyway
//     }
//   }

//   Future<void> _verifyToken(String token) async {
//     try {
//       await Supabase.instance.client.auth.verifyOTP(
//         type: OtpType.recovery,
//         token: token,
//       );
//       setState(() => _verifying = false);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('رمز الاستعادة غير صالح أو منتهي الصلاحية')),
//       );
//       Navigator.pop(context);
//     }
//   }

//   Future<void> _updatePassword() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         await Supabase.instance.client.auth.updateUser(
//           UserAttributes(password: _passwordController.text.trim()),
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
//         );

//         Navigator.pushNamedAndRemoveUntil(
//           context,
//           SignInPage.signinRoute,
//           (route) => false,
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('حدث خطأ أثناء تحديث كلمة المرور: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(title: Text('تغيير كلمة المرور')),
//         body: _verifying
//             ? Center(child: CircularProgressIndicator())
//             : Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: [
//                       TextFormField(
//                         controller: _passwordController,
//                         obscureText: true,
//                         decoration: customInputDecoration.copyWith(
//                           labelText: 'كلمة مرور جديدة',
//                         ),
//                         validator: (value) {
//                           if (value == null || value.length < 8) {
//                             return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
//                           }
//                           return null;
//                         },
//                       ),
//                       SizedBox(height: 20),
//                       ElevatedButton(
//                         onPressed: _updatePassword,
//                         child: Text('تحديث كلمة المرور'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }
// }
