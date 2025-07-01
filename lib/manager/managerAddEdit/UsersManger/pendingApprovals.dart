import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/manager/managerAddEdit/UsersManger/usersApprovalDetails.dart';

class PendingApprovalsPage extends StatefulWidget {
  static const String routeName = 'pendingApprovals';

  @override
  State<PendingApprovalsPage> createState() => _PendingApprovalsPageState();
}

class _PendingApprovalsPageState extends State<PendingApprovalsPage> {
  List<Map<String, dynamic>> pendingUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  Future<void> _fetchPendingUsers() async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('users')
        .select()
        .eq('is_approved', false);
    setState(() {
      pendingUsers = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _approveUser(String id) async {
    await Supabase.instance.client
        .from('users')
        .update({'is_approved': true})
        .eq('id', id);

    // ✅ Refresh local list
    await _fetchPendingUsers();

    // ✅ Return to previous page to trigger refresh if no more pending users
    if (pendingUsers.isEmpty) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteUser(String id) async {
    await Supabase.instance.client.from('users').delete().eq('id', id);

  
    await _fetchPendingUsers();

    // ✅ Return if all users deleted
    if (pendingUsers.isEmpty) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: const Text(
              'عرض جميع الطلبات',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingUsers.length,
                  itemBuilder: (context, index) {
                    final user = pendingUsers[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(user['name'] ?? ''),
                        subtitle: Text('${user['email']} - ${user['role']}'),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => UserApprovalDetailPage(
                                    userId: user['id'],
                                  ),
                            ),
                          );

                          // ✅ If user approved inside detail page, refresh
                          if (result == true) {
                            await _fetchPendingUsers();
                            if (pendingUsers.isEmpty) {
                              Navigator.of(context).pop(true);
                            }
                          }
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                await _approveUser(user['id']);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: AlertDialog(
                                          title: const Text('تأكيد الحذف'),
                                          content: const Text(
                                            'هل أنت متأكد من حذف هذا المستخدم؟',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                              child: const Text('إلغاء'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                              child: const Text('نعم'),
                                            ),
                                          ],
                                        ),
                                      ),
                                );

                                if (confirm == true) {
                                  await _deleteUser(user['id']);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
