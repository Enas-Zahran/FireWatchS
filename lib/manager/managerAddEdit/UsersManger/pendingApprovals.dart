import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingApprovalsPage extends StatefulWidget {
  static const String routeName = 'approval_pending';

  @override
  _PendingApprovalsPageState createState() => _PendingApprovalsPageState();
}

class _PendingApprovalsPageState extends State<PendingApprovalsPage> {
  late Future<List<Map<String, dynamic>>> _pendingUsersFuture;

  @override
  void initState() {
    super.initState();
    _pendingUsersFuture = _fetchPendingUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingUsers() async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('is_approved', false); // only not approved users

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _approveUser(String userId) async {
    await Supabase.instance.client
        .from('profiles')
        .update({'is_approved': true})
        .eq('id', userId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت الموافقة على المستخدم')),
    );

    // Refresh the list
    setState(() {
      _pendingUsersFuture = _fetchPendingUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('طلبات الموافقة'),
          backgroundColor: Color(0xff00408b),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _pendingUsersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }
            final users = snapshot.data!;
            if (users.isEmpty) {
              return Center(child: Text('لا يوجد مستخدمين بحاجة إلى موافقة'));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(user['name'] ?? 'بدون اسم'),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: ElevatedButton(
                      onPressed: () => _approveUser(user['id']),
                      child: Text('الموافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
