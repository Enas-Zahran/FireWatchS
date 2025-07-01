import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/manager/managerAddEdit/UsersManger/pendingApprovals.dart';
import 'package:FireWatch/manager/managerAddEdit/UsersManger/editUser.dart';

//Todo material type filter and tool type isn't working correctly
class ManagerUserListPage extends StatefulWidget {
  static const String routeName = 'managerUserList';

  @override
  State<ManagerUserListPage> createState() => _ManagerUserListPageState();
}

class _ManagerUserListPageState extends State<ManagerUserListPage> {
  final _searchController = TextEditingController();
  bool _hasPendingRequests = false;
  List<String> selectedTaskRanges = [];
  List<String> selectedToolTypes = [];
  List<String> selectedMaterialTypes = [];
  List<String> selectedWorkPlaces = [];

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool _loading = true;

  final taskRanges = ['1-10', '10-20', '20-30', '30+'];
  final toolTypes = ['fire extinguisher', 'hose reel', 'fire hydrant'];
  final materialTypes = [
    'ثاني اكسيد الكربون',
    'البودرة الجافة',
    'الرغوة (B.C.F)',
    'الماء',
    'البودرة الجافة ذات مستشعر حرارة الاتوماتيكي',
  ];

  final workPlaces = ['هندسية', 'طبية', 'خدمات', 'مباني خارجية'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _checkPendingRequests();
  }

  Future<void> _checkPendingRequests() async {
    final data = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('is_approved', false)
        .limit(1);

    setState(() {
      _hasPendingRequests = data.isNotEmpty;
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('users')
        .select()
        .eq('is_approved', true)
        .neq('role', 'المدير');
    allUsers = List<Map<String, dynamic>>.from(data);
    _applyFilters();
    _loading = false;
    setState(() {});
  }

  bool containsAny(dynamic rawValue, List<String> selected) {
    print('RAW VALUE: $rawValue');
    if (rawValue == null || selected.isEmpty) return false;

    if (rawValue is List) {
      return selected.any((item) => rawValue.contains(item));
    }

    try {
      final decoded = jsonDecode(rawValue.toString());
      if (decoded is List) {
        return selected.any((item) => decoded.contains(item));
      }
    } catch (_) {}

    return false;
  }

  void _applyFilters() {
    final searchName = _searchController.text.trim();
    filteredUsers =
        allUsers.where((user) {
          final taskCount = user['task_count'] ?? 0;

          bool matchesTask =
              selectedTaskRanges.isEmpty ||
              selectedTaskRanges.any((range) {
                if (range == '1-10') return taskCount <= 10;
                if (range == '10-20') return taskCount > 10 && taskCount <= 20;
                if (range == '20-30') return taskCount > 20 && taskCount <= 30;
                if (range == '30+') return taskCount > 30;
                return false;
              });

          final matchesTool =
              selectedToolTypes.isEmpty ||
              containsAny(user['tool_type'], selectedToolTypes);

          final matchesMaterial =
              selectedMaterialTypes.isEmpty ||
              containsAny(user['material_type'], selectedMaterialTypes);

          final matchesWorkPlace =
              selectedWorkPlaces.isEmpty ||
              containsAny(user['work_place'], selectedWorkPlaces);

          final matchesName =
              searchName.isEmpty ||
              (user['name']?.toString().toLowerCase().contains(
                    searchName.toLowerCase(),
                  ) ??
                  false);

          return matchesTask &&
              matchesTool &&
              matchesMaterial &&
              matchesWorkPlace &&
              matchesName;
        }).toList();
  }

  Widget _buildCheckboxList(
    String title,
    List<String> options,
    List<String> selectedItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...options.map(
          (item) => CheckboxListTile(
            value: selectedItems.contains(item),
            title: Text(item),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  selectedItems.add(item);
                } else {
                  selectedItems.remove(item);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'عرض جميع المستخدمين',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => Align(
                        alignment: Alignment.topCenter,
                        child: Material(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(top: 40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('أدخل اسم المستخدم'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _searchController,
                                  onChanged:
                                      (_) => setState(() => _applyFilters()),
                                  decoration: InputDecoration(
                                    hintText: 'ابحث...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  child: const Text('إغلاق'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                );
              },
            ),
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
            ),
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.mail, color: Colors.white),
                  if (_hasPendingRequests)
                    const Positioned(
                      top: -4,
                      right: -4,
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Color(0xffae2f34),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PendingApprovalsPage(),
                  ),
                );
                if (result == true) {
                  _fetchUsers();
                }
                _checkPendingRequests();
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'الفلاتر',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildCheckboxList(
                  'عدد المهام',
                  taskRanges,
                  selectedTaskRanges,
                ),
                _buildCheckboxList('نوع الأداة', toolTypes, selectedToolTypes),
                _buildCheckboxList(
                  'نوع المادة',
                  materialTypes,
                  selectedMaterialTypes,
                ),
                _buildCheckboxList(
                  'مكان العمل',
                  workPlaces,
                  selectedWorkPlaces,
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _applyFilters());
                    Navigator.pop(context);
                  },
                  child: const Text('تطبيق الفلاتر'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedTaskRanges.clear();
                      selectedToolTypes.clear();
                      selectedMaterialTypes.clear();
                      selectedWorkPlaces.clear();
                      _applyFilters();
                    });
                  },
                  child: const Text('إعادة تعيين'),
                ),
              ],
            ),
          ),
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      filteredUsers.isEmpty
                          ? const Center(child: Text('لا يوجد مستخدمون'))
                          : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(user['name'] ?? ''),
                                  subtitle: Text(
                                    '${user['email']} - ${user['role']}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => EditUserPage(
                                                    userId: user['id'],
                                                  ),
                                            ),
                                          );
                                          if (result == true) {
                                            _fetchUsers();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => Directionality(
                                                  textDirection: TextDirection.rtl,
                                                  child: AlertDialog(
                                                    title: const Text(
                                                      'تأكيد الحذف',
                                                    ),
                                                    content: const Text(
                                                      'هل أنت متأكد من حذف هذا المستخدم؟',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'إلغاء',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text('نعم'),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          );
                                          if (confirm == true) {
                                            await Supabase.instance.client
                                                .from('users')
                                                .delete()
                                                .eq('id', user['id']);
                                            await _fetchUsers();
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
      ),
    );
  }
}
