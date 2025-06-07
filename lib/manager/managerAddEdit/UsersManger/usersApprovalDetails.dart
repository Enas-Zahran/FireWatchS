import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/Supabase/profiles.dart';
class UserApprovalDetailsPage extends StatelessWidget {
  final Profile user;

  const UserApprovalDetailsPage({required this.user});

  void approveUser(BuildContext context) async {
    await Supabase.instance.client
        .from('profiles')
        .update({'is_approved': true})
        .eq('id', user.id);

    Navigator.pop(context); // back to list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل الحساب')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('الاسم: ${user.fullName}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('البريد الإلكتروني: ${user.email}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('الدور: ${user.role}', style: TextStyle(fontSize: 18)),
            Spacer(),
            ElevatedButton(
              onPressed: () => approveUser(context),
              child: Text('موافق'),
            ),
          ],
        ),
      ),
    );
  }
}
