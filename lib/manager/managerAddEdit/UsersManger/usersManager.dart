import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/Supabase/profiles.dart';
import 'package:FireWatch/manager/managerAddEdit/UsersManger/pendingApprovals.dart';

class ManagerUserListPage extends StatefulWidget {
  @override
  _ManagerUserListPageState createState() => _ManagerUserListPageState();
}

class _ManagerUserListPageState extends State<ManagerUserListPage> {
  List<Profile> approvedUsers = [];

  @override
  void initState() {
    super.initState();
    fetchApprovedUsers();
  }

  Future<void> fetchApprovedUsers() async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('is_approved', true);

    setState(() {
      approvedUsers =
          (response as List).map((user) => Profile.fromJson(user)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text(
              'قائمة المستخدمين المعتمدين',
              style: TextStyle(color: Colors.white),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
            IconButton(icon: const Icon(Icons.filter_list, color: Colors.white), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PendingApprovalsPage()),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: approvedUsers.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: approvedUsers.length,
                  itemBuilder: (context, index) {
                    final user = approvedUsers[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            user.fullName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text('${user.email} - ${user.role}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  // TODO: implement edit logic
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('تأكيد الحذف'),
                                        content: const Text('هل أنت متأكد من حذف هذا المستخدم؟'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('إلغاء'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('نعم'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirm == true) {
                                    await Supabase.instance.client
                                        .from('profiles')
                                        .delete()
                                        .eq('id', user.id);
                                    fetchApprovedUsers();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
