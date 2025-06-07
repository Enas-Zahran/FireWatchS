// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../My/InputDecoration.dart'; // Your custom styling

// class ResetPasswordRequestPage extends StatefulWidget {
//   static const String routeName = '/request-reset';

//   @override
//   _ResetPasswordRequestPageState createState() => _ResetPasswordRequestPageState();
// }

// class _ResetPasswordRequestPageState extends State<ResetPasswordRequestPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();

//   Future<void> _requestReset() async {
//     if (_formKey.currentState!.validate()) {
//       final email = _emailController.text.trim();
//       try {
//         await Supabase.instance.client.auth.resetPasswordForEmail(
//           email,
//           redirectTo: 'firewatch://reset-password', 
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني')),
//         );
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('فشل في إرسال رابط إعادة تعيين: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(title: Text('إعادة تعيين كلمة المرور')),
//         body: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: customInputDecoration.copyWith(
//                     labelText: 'البريد الإلكتروني',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _requestReset,
//                   child: Text('إرسال رابط إعادة التعيين'),
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
