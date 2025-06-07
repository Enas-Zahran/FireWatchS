// ManagerUserListPage with multi-select filters in Drawer

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';
import 'package:FireWatch/manager/managerAddEdit/UsersManger/pendingApprovals.dart';

class ManagerUserListPage extends StatefulWidget {
  static const String routeName = 'managerUserList';

  @override
  State<ManagerUserListPage> createState() => _ManagerUserListPageState();
}

class _ManagerUserListPageState extends State<ManagerUserListPage> {
  final _searchController = TextEditingController();

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
    'طفايات ثاني أوكسيد الكربون',
    'طفايات البودرة الجافة',
    'طفايات الرغوة (B.C.F)',
    'طفايات الماء',
    'طفايات البودرة الجافة ذات مستشعر حرارة الأتوماتيكي',
  ];
  final workPlaces = ['هندسية', 'طبية', 'خدمات', 'مباني خارجية'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('users')
        .select()
        .eq('is_approved', true);
    allUsers = List<Map<String, dynamic>>.from(data);
    _applyFilters();
    _loading = false;
    setState(() {});
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
              selectedToolTypes.contains(user['tool_type']?.toString());
          final matchesMaterial =
              selectedMaterialTypes.isEmpty ||
              selectedMaterialTypes.contains(user['material_type']?.toString());
          final matchesWorkPlace =
              selectedWorkPlaces.isEmpty ||
              selectedWorkPlaces.contains(user['work_place']?.toString());
          final matchesName =
              searchName.isEmpty ||
              (user['name']?.toString().toLowerCase().contains(searchName.toLowerCase()) ?? false);


          return matchesTask &&
              matchesTool &&
              matchesMaterial &&
              matchesWorkPlace &&
              matchesName;
        }).toList();
  }

  void _openFilterDrawer() {
    Scaffold.of(context).openEndDrawer();
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
                showModalBottomSheet(
                  context: context,
                  builder:
                      (_) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() => _applyFilters()),
                          decoration: customInputDecoration.copyWith(
                            labelText: 'ابحث باسم المستخدم',
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
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PendingApprovalsPage()),
                );
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
                    Navigator.pop(context);
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
                          ? const Text('لا يوجد مستخدمون')
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
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                          ),
                ),
      ),
    );
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
}
