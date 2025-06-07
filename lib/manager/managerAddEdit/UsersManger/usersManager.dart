import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';

class ManagerUserListPage extends StatefulWidget {
  static const String routeName = 'managerUserList';

  @override
  State<ManagerUserListPage> createState() => _ManagerUserListPageState();
}

class _ManagerUserListPageState extends State<ManagerUserListPage> {
  final _searchController = TextEditingController();
  String? _taskFilter;
  String? _toolFilter;
  String? _materialFilter;
  String? _workPlaceFilter;

  List<Map<String, dynamic>> users = [];
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
    final query = Supabase.instance.client
        .from('users')
        .select()
        .eq('is_approved', true);

    final data = await query;
    setState(() {
      users = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
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
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        _buildDropdown('عدد المهام', taskRanges, _taskFilter, (
                          val,
                        ) {
                          setState(() => _taskFilter = val);
                        }),
                        _buildDropdown('نوع الأداة', toolTypes, _toolFilter, (
                          val,
                        ) {
                          setState(() => _toolFilter = val);
                        }),
                        _buildDropdown(
                          'نوع المادة',
                          materialTypes,
                          _materialFilter,
                          (val) {
                            setState(() => _materialFilter = val);
                          },
                        ),
                        _buildDropdown(
                          'مكان العمل',
                          workPlaces,
                          _workPlaceFilter,
                          (val) {
                            setState(() => _workPlaceFilter = val);
                          },
                        ),
                        const SizedBox(height: 20),
                        ...users.map(
                          (user) => Card(
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 400,
      child: TextField(
        controller: _searchController,
        decoration: customInputDecoration.copyWith(
          labelText: 'ابحث باسم المستخدم',
          hintText: 'اكتب جزءًا من الاسم',
        ),
        onChanged: (value) {
          // optional: implement search filtering
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 400,
      child: DropdownButtonFormField<String>(
        decoration: customInputDecoration.copyWith(labelText: label),
        value: value,
        onChanged: onChanged,
        items:
            items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
      ),
    );
  }
}
