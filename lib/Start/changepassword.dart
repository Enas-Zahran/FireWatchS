// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:FireWatch/My/InputDecoration.dart';

// class NewPasswordPage extends StatefulWidget {
//   static const String routeName = 'newPassword';

//   @override
//   State<NewPasswordPage> createState() => _NewPasswordPageState();
// }

// class _NewPasswordPageState extends State<NewPasswordPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _isVisible = false;

//   Future<void> _updatePassword() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
//       try {
//         await Supabase.instance.client.auth.updateUser(
//           UserAttributes(password: _passwordController.text.trim()),
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
//         );

//         // يمكنك توجيه المستخدم لصفحة تسجيل الدخول
//         Navigator.of(context).popUntil((route) => route.isFirst);
//       } catch (error) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('فشل في تغيير كلمة المرور: $error')),
//         );
//       } finally {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('تعيين كلمة مرور جديدة'),
//           backgroundColor: Color(0xff00408b),
//           iconTheme: IconThemeData(color: Colors.white),
//         ),
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('أدخل كلمة المرور الجديدة الخاصة بك:', style: theme.textTheme.bodyLarge),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: 400,
//                     child: TextFormField(
//                       controller: _passwordController,
//                       obscureText: !_isVisible,
//                       obscuringCharacter: '*',
//                       decoration: customInputDecoration.copyWith(
//                         labelText: 'كلمة المرور الجديدة',
//                         hintText: '8 أحرف على الأقل',
//                         prefixIcon: IconButton(
//                           icon: Icon(
//                             _isVisible ? Icons.visibility : Icons.visibility_off,
//                             color: Color(0xff00408b),
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _isVisible = !_isVisible;
//                             });
//                           },
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.length < 8) {
//                           return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: _isLoading ? null : _updatePassword,
//                     child: _isLoading
//                         ? CircularProgressIndicator(color: Colors.white)
//                         : Text('تحديث كلمة المرور', style: TextStyle(color: Colors.white)),
//                     style: ElevatedButton.styleFrom(
//                       minimumSize: const Size(400, 50),
//                       backgroundColor: const Color(0xff00408b),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
