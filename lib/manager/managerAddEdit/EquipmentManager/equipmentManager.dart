import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/My/InputDecoration.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/toolDetails.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/addSafteyTool.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/editSafteyTool.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/Permessions/exportRequests.dart';
import 'package:FireWatch/technician/MaterialExit.dart';

//Todo السعر لازم يتغير تلقائي حسب النوع
class AllToolsPage extends StatefulWidget {
  @override
  State<AllToolsPage> createState() => _AllToolsPageState();
}

class _AllToolsPageState extends State<AllToolsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> tools = [];
  List<Map<String, dynamic>> filteredTools = [];
  bool loading = true;
  String? userRole;
  String? technicianName;
  bool _hasPendingRequests = false;
  Future<void> _fetchUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data =
        await Supabase.instance.client
            .from('users')
            .select('role, name')
            .eq('id', user.id)
            .maybeSingle();

    setState(() {
      userRole = data?['role'];
      technicianName = data?['name'];
    });
  }

  Future<void> _checkPendingRequests() async {
    final data = await Supabase.instance.client
        .from('export_requests')
        .select()
        .eq('status', 'pending');

    setState(() {
      _hasPendingRequests = data.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchTools();
    _checkPendingRequests();
    _fetchUserRole();
  }

  Future<void> _fetchTools() async {
    setState(() => loading = true);
    final data = await Supabase.instance.client
        .from('safety_tools')
        .select()
        .order('created_at', ascending: false);

    tools = List<Map<String, dynamic>>.from(data);
    _applySearch();
    setState(() => loading = false);
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    filteredTools =
        tools.where((tool) {
          final name = tool['name']?.toString().toLowerCase() ?? '';
          final type = tool['type']?.toString().toLowerCase() ?? '';
          final material =
              tool['material_type']?.toString().toLowerCase() ?? '';
          return name.contains(query) ||
              type.contains(query) ||
              material.contains(query);
        }).toList();
  }

  void _goToAddTool() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSafetyToolPage()),
    );
  }

  void _goToDetails(Map<String, dynamic> tool) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ToolDetailsPage(tool: tool)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: const Text(
              'عرض جميع المعدات',
              style: TextStyle(color: Colors.white),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: true,

          actions: [
            IconButton(icon: const Icon(Icons.add), onPressed: _goToAddTool),
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
                //                 if (userRole == 'فني السلامة العامة') {
                //                   final extinguisherReports = await Supabase.instance.client
                //                       .from('fire_extinguisher_reports')
                //                       .select('tool_name, steps, other_notes')
                //                       .eq('technician_name', technicianName ?? '');

                //                   final hydrantReports = await Supabase.instance.client
                //                       .from('fire_hydrant_reports')
                //                       .select('tool_name, steps, other_notes')
                //                       .eq('technician_name', technicianName ?? '');

                //                   final hoseReelReports = await Supabase.instance.client
                //                       .from('hose_reel_reports')
                //                       .select('tool_name, steps, other_notes')
                //                       .eq('technician_name', technicianName ?? '');

                //                   final allReports = [
                //                     ...extinguisherReports,
                //                     ...hydrantReports,
                //                     ...hoseReelReports,
                //                   ];
                //                   final List<Map<String, dynamic>> materialsToExport = [];

                //                   for (var report in allReports) {
                //                     final tool = report['tool_name'];
                //                     final steps = List<Map<String, dynamic>>.from(
                //                       report['steps'] ?? [],
                //                     );
                //                     for (var step in steps) {
                //                       final note = step['note']?.toString().trim();
                //                       if (note != null && note.isNotEmpty) {
                //                         materialsToExport.add({'toolName': tool, 'note': note});
                //                       }
                //                     }
                //                     final otherNote = report['other_notes']?.toString().trim();
                //                     if (otherNote != null && otherNote.isNotEmpty) {
                //                       materialsToExport.add({
                //                         'toolName': tool,
                //                         'note': otherNote,
                //                       });
                //                     }
                //                   }

                //                   if (materialsToExport.isEmpty) {
                //                     ScaffoldMessenger.of(context).showSnackBar(
                //                       const SnackBar(
                //                         content: Text('لا يوجد أدوات تحتوي على ملاحظات'),
                //                       ),
                //                     );
                //                     return;
                //                   }

                //                   final reasonText = materialsToExport
                //                       .map((e) => e['note'])
                //                       .join(' - ');

                //                   Navigator.push(
                //                     context,
                //                     MaterialPageRoute(
                //                       builder:
                //                           (_) => MaterialExitAuthorizationPage(

                //                           ),
                //                     ),
                //                   );
                //                } else {
                //   final result = await
                // //   Navigator.push(
                // //   context,
                // //   MaterialPageRoute(
                // //     builder: (_) => ExportRequestMaterialsPage(

                // //     ),
                // //   ),
                // // );

                //   if (result == true) _checkPendingRequests();
                // }
              },
            ),
          ],
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() => _applySearch()),
                        decoration: customInputDecoration.copyWith(
                          labelText: 'ابحث باسم الاداة',
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child:
                            filteredTools.isEmpty
                                ? const Center(child: Text('لا يوجد معدات'))
                                : ListView.builder(
                                  itemCount: filteredTools.length,
                                  itemBuilder: (context, index) {
                                    final tool = filteredTools[index];
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(tool['name'] ?? ''),
                                              subtitle: Text(
                                                '${tool['type']} - ${tool['capacity']}',
                                              ),
                                              trailing: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'آخر صيانة: ${tool['last_maintenance_date'] ?? 'غير محدد'}',
                                                  ),
                                                  Text(
                                                    'القادمة: ${tool['next_maintenance_date'] ?? 'غير محدد'}',
                                                  ),
                                                ],
                                              ),
                                              onTap: () => _goToDetails(tool),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  onPressed: () async {
                                                    final result =
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (_) =>
                                                                    EditSafetyToolPage(
                                                                      tool:
                                                                          tool,
                                                                    ),
                                                          ),
                                                        );

                                                    if (result == true)
                                                      await _fetchTools();
                                                  },

                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    final confirm = await showDialog<
                                                      bool
                                                    >(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: const Text(
                                                              'تأكيد الحذف',
                                                            ),
                                                            content: Text(
                                                              'هل أنت متأكد من حذف الأداة "${tool['name']}"؟',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'إلغاء',
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'نعم',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                    if (confirm == true) {
                                                      await Supabase
                                                          .instance
                                                          .client
                                                          .from('safety_tools')
                                                          .delete()
                                                          .eq('id', tool['id']);
                                                      await _fetchTools();
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
